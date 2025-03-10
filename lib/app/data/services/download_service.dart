import 'package:background_downloader/background_downloader.dart';
import 'package:get/get.dart';
import 'package:oktoast/oktoast.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/utils/display_util.dart';
import '../models/download_task.dart';
import '../models/offline/download_task_media.dart';
import '../providers/storage_provider.dart';

class DownloadTaskStatus {
  TaskStatus status;
  double progress;

  DownloadTaskStatus({required this.status, required this.progress});
}

class DownloadService extends GetxService {
  final RxMap<String, Rx<DownloadTaskStatus>> _downloadTasks =
      <String, Rx<DownloadTaskStatus>>{}.obs;

  RxMap<String, Rx<DownloadTaskStatus>> get downloadTasksStatus =>
      _downloadTasks;

  List<DownloadTask> currentTasks = [];

  @override
  void onInit() {
    super.onInit();
    FileDownloader().trackTasks();
    FileDownloader().updates.listen((update) {
      if (update is TaskStatusUpdate) {
        _downloadTasks[update.task.taskId]?.value.status = update.status;
        _downloadTasks.refresh();
      } else if (update is TaskProgressUpdate) {
        _downloadTasks[update.task.taskId]?.value.progress = update.progress;
        _downloadTasks.refresh();
      }
    });
    _getVideoTasksFromRecords();
  }

  void _getVideoTasksFromRecords() async {
    var records = await FileDownloader().database.allRecords();
    if (records.isNotEmpty) {
      for (var record in records) {
        _downloadTasks.assign(
          record.task.taskId,
          DownloadTaskStatus(
            status: record.status,
            progress: record.progress,
          ).obs,
        );
      }
    }
    _downloadTasks.refresh();
  }

  Future<bool> _checkPermission() async {
    final status = await Permission.storage.status;
    if (status.isGranted) {
      return true;
    } else {
      final result = await Permission.storage.request();
      if (result.isGranted) {
        return true;
      } else {
        return false;
      }
    }
  }

  Future<Map<String, dynamic>?> addDownloadTask({
    required String downloadUrl,
    required String fileName,
    required String subDirectory,
    required String title,
  }) async {
    bool isStorage = await _checkPermission();
    if (!isStorage) {
      showToast(DisplayUtil.messageNoStoragePermission);
      return null;
    }
    var records = await FileDownloader().database.allRecords();
    if (records.isNotEmpty) {
      bool hasExisted =
          records.any((var record) => record.task.filename == fileName);
      if (hasExisted) {
        showToast(DisplayUtil.messageDownloadTaskAlreadyExist);
        return null;
      }
    }
    DownloadTask task = DownloadTask(
      url: downloadUrl,
      filename: fileName,
      updates: Updates.statusAndProgress,
      directory: "downloads$subDirectory",
      baseDirectory: BaseDirectory.applicationDocuments,
      allowPause: true,
    );
    FileDownloader().configureNotificationForTask(
      task,
      running: TaskNotification(DisplayUtil.downloadDownloading, title),
      paused: TaskNotification(DisplayUtil.downloadPaused, title),
      complete: TaskNotification(DisplayUtil.downloadFinished, title),
      error: TaskNotification(DisplayUtil.downloadFailed, title),
      progressBar: true,
    );
    await FileDownloader().enqueue(task);
    return task.toJsonMap();
  }

  Future<bool> addVideoDownloadTask({
    required String url,
    required String resolutionName,
    required DownloadTaskMediaModel offlineMedia,
  }) async {
    Map<String, dynamic>? downloadTask;

    DateTime now = DateTime.now();
    Uri uri = Uri.parse(url);
    int expireTime = int.parse(uri.queryParameters['expires']!);
    String fileName = uri.queryParameters['filename']!.split(".").first;

    await addDownloadTask(
      downloadUrl: url,
      fileName: fileName,
      subDirectory: "/videos/${offlineMedia.id}",
      title: offlineMedia.title,
    ).then((value) {
      downloadTask = value;
    });

    if (downloadTask != null) {
      var task = VideoDownloadTask(
        task: downloadTask!,
        createTime: now,
        expireTime: expireTime,
        resolutionName: resolutionName,
        offlineMedia: offlineMedia,
      );
      var taskData = DownloadTask.fromJsonMap(downloadTask!);

      _downloadTasks.addAll({
        taskData.taskId: DownloadTaskStatus(
          status: TaskStatus.enqueued,
          progress: 0,
        ).obs
      });

      currentTasks.add(taskData);

      StorageProvider.addDownloadVideoRecord(task);
      return true;
    } else {
      return false;
    }
  }

  void pauseAllTasks() {
    for (var task in currentTasks) {
      if (_downloadTasks[task.taskId]?.value.status == TaskStatus.running) {
        pauseTask(task);
      }
    }
  }

  Future<bool> pauseTask(DownloadTask task) {
    return FileDownloader().pause(task);
  }

  Future<bool> resumeTask(DownloadTask task) {
    return FileDownloader().resume(task);
  }

  Future<bool> cancelTask(String taskId) {
    return FileDownloader().cancelTaskWithId(taskId);
  }

  Future<void> deleteTaskRecord(String taskId) async {
    await FileDownloader().database.deleteRecordWithId(taskId);
  }
}

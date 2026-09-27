// 定时备份文件保存：IO 平台写应用文档目录固定文件，Web 端存浏览器
// localStorage。固定位置 = 天然「只覆盖上一次定时备份」，与手动备份
// （用户另存为 xupurse_backup_<时间戳>.json）互不干扰。
export 'auto_backup_store_io.dart'
    if (dart.library.html) 'auto_backup_store_web.dart';

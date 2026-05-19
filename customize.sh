pm install -r "$MODPATH/system/usr/share/AIWallpaper.apk"
set_perm_recursive $MODPATH/system/vendor/bin root root 0755 0755
set_perm $MODPATH/system/vendor/bin/add.pb root root 0644
set_perm_recursive $MODPATH/system/etc root root 0755 0644
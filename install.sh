#########################################
# Magisk Module Installer Configuration #
#########################################

# Required flags for Magisk installer
SKIPMOUNT=false
PROPFILE=true
POSTFSDATA=false
LATESTARTSERVICE=false

# Use Magisk's built-in ui_print/abort; do not override

# Function to check for volume key input
get_key_input() {
  ui_print " "
  ui_print "Please confirm installation:"
  ui_print "   Vol Up   = YES, Please"
  ui_print "   Vol Down = NO, cancel"

  while true; do
    KEY=$(getevent -lc 1 2>&1 | grep 'KEY_')
    if $(echo "$KEY" | grep -q "KEY_VOLUMEUP"); then
      return 0
    elif $(echo "$KEY" | grep -q "KEY_VOLUMEDOWN"); then
      return 1
    fi
  done
}

# Printed by Magisk before installation proceeds
print_modname() {
  ui_print " "
  ui_print "*********************************"
  ui_print "  One UI (8.0)  Feature Adder For A325F"
  ui_print "  Noone"
  ui_print "*********************************"
  ui_print " "
}

# Main installation routine
on_install() {
  # Detect Android version
  SDK_VERSION=$(getprop ro.build.version.sdk)
  ANDROID_RELEASE=$(getprop ro.build.version.release)
  ANDROID_MAJOR=$(echo "$ANDROID_RELEASE" | cut -d. -f1)
  IS_ANDROID_16=0
  if [ "$SDK_VERSION" = "36" ] || [ "$ANDROID_MAJOR" = "16" ]; then
    IS_ANDROID_16=1
  fi

  # Show detected version and warn if not Android 16
  ui_print "Detected Android $ANDROID_RELEASE (SDK $SDK_VERSION)"
  if [ "$IS_ANDROID_16" -ne 1 ]; then
    ui_print " "
    ui_print "**************************************************************"
    ui_print " WARNING: This module targets Android 16 (One UI 8)."
    ui_print "          Your device reports Android $ANDROID_RELEASE (SDK $SDK_VERSION)."
    ui_print "          Proceeding may not work as expected."
    ui_print "**************************************************************"
  fi

  # Disclaimer
  ui_print " "
  ui_print " Your warranty is now void."
  ui_print " I am not responsible for bricked devices, dead SD cards,"
  ui_print " thermonuclear war, or you getting fired because the alarm app"
  ui_print " failed. YOU are choosing to make these modifications."
  ui_print " "

  # Single confirmation
  if ! get_key_input; then
    abort "Cancelled by user (Volume Down)."
  fi
  ui_print " "
  ui_print "Installation confirmed (Volume Up)."

  # Extract module files into $MODPATH
  ui_print "- Extracting module files"
  unzip -o "$ZIPFILE" -x 'META-INF/*' 'install.sh' -d "$MODPATH" >&2

  # Merge floating features safely (Prevent overwriting device specifics)
  if [ -f "$MODPATH/s26_features.xml" ]; then
    ui_print "- Merging S26 Floating Features"
    mkdir -p "$MODPATH/system/etc"
    
    # Copy device original to module
    cp "/system/etc/floating_feature.xml" "$MODPATH/system/etc/floating_feature.xml"

    # Loop through S26 features and inject/replace in target file
    # We filter for SEC_FLOATING_FEATURE to avoid copying garbage
    grep "SEC_FLOATING_FEATURE" "$MODPATH/s26_features.xml" | while read -r line; do
      # Clean line endings and extract the feature tag name
      clean_line=$(echo "$line" | tr -d '\r')
      feature_tag=$(echo "$clean_line" | cut -d'<' -f2 | cut -d'>' -f1)
      
      if [ -n "$feature_tag" ]; then
        # If feature exists in device file, replace it. If not, append it before the closing tag.
        if grep -q "<$feature_tag>" "$MODPATH/system/etc/floating_feature.xml"; then
          sed -i "s|.*<$feature_tag>.*|$clean_line|" "$MODPATH/system/etc/floating_feature.xml"
        else
          sed -i "/<\/SecFloatingFeatureSet>/i $clean_line" "$MODPATH/system/etc/floating_feature.xml"
        fi
      fi
    done
    
    # Cleanup
    rm "$MODPATH/s26_features.xml"
  fi
}

# Set permissions for installed files
set_permissions() {
  # Default: directories 0755, files 0644
  set_perm_recursive "$MODPATH" 0 0 0755 0644
}
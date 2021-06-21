# app_tracking

A new Flutter project.

## Getting Started


---------------------------------------------------------------------------------------------

Android:

**** app/build.gradle ****
dependencies {
    implementation platform('com.google.firebase:firebase-bom:28.1.0')
    implementation 'com.google.firebase:firebase-analytics-ktx'
}


apply plugin: 'com.google.gms.google-services'
apply plugin: 'com.google.firebase.crashlytics'


/////////////////////////////////////////////////////////////////////////////

**** android/build.gradle ****
dependencies {
  classpath 'com.google.gms:google-services:4.3.5'
  classpath 'com.google.firebase:firebase-crashlytics-gradle:2.5.1'
}


---------------------------------------------------------------------------------------------

iOS:

From Xcode select Runner from the project navigation.
Select the Build Phases tab, then click + > New Run Script Phase.
Add ${PODS_ROOT}/FirebaseCrashlytics/run to the Type a script... text box.
Optionally you can also provide your app's built Info.plist location to the build phase's Input Files field:
For example: $(BUILT_PRODUCTS_DIR)/$(INFOPLIST_PATH)
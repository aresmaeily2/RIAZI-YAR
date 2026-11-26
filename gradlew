#!/bin/sh
# Minimal POSIX launcher delegating to system gradle if gradle-wrapper.jar is absent
if [ -f "$(dirname "$0")/gradle/wrapper/gradle-wrapper.jar" ]; then
  exec java -classpath "$(dirname "$0")/gradle/wrapper/gradle-wrapper.jar" org.gradle.wrapper.GradleWrapperMain "$@"
else
  exec gradle "$@"
fi

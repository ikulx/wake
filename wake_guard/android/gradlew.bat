@ECHO OFF
SET DIR=%~dp0
SET APP_HOME=%DIR%

SET DEFAULT_JVM_OPTS=

IF NOT "%JAVA_HOME%"=="" (
  SET JAVA_EXE=%JAVA_HOME%\bin\java.exe
  IF EXIST "%JAVA_EXE%" goto init
)

SET JAVA_EXE=java.exe

:init
SET CLASSPATH=%APP_HOME%\gradle\wrapper\gradle-wrapper.jar
"%JAVA_EXE%" %DEFAULT_JVM_OPTS% -classpath "%CLASSPATH%" org.gradle.wrapper.GradleWrapperMain %*

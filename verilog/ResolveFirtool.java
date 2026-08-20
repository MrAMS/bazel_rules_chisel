import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.InputStream;
import java.lang.reflect.Method;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;

public final class ResolveFirtool {
  private ResolveFirtool() {}

  public static void main(String[] args) throws Exception {
    if (args.length != 1) {
      throw new IllegalArgumentException("Usage: ResolveFirtool <output-file>");
    }

    Object buildInfo = Class.forName("chisel3.BuildInfo$").getField("MODULE$").get(null);
    Object versionOption = buildInfo.getClass().getMethod("firtoolVersion").invoke(buildInfo);
    Method isDefined = versionOption.getClass().getMethod("isDefined");
    if (!(Boolean) isDefined.invoke(versionOption)) {
      throw new IllegalStateException("The configured Chisel artifact does not declare a firtool version");
    }
    String version = (String) versionOption.getClass().getMethod("get").invoke(versionOption);

    String javaExecutable = Paths.get(
            System.getProperty("java.home"),
            "bin",
            System.getProperty("os.name").toLowerCase().startsWith("windows") ? "java.exe" : "java")
        .toString();
    ProcessBuilder processBuilder = new ProcessBuilder(
        javaExecutable,
        "-cp",
        System.getProperty("java.class.path"),
        "firtoolresolver.Main",
        version);
    processBuilder.environment().remove("CHISEL_FIRTOOL_PATH");
    processBuilder.redirectError(ProcessBuilder.Redirect.INHERIT);

    Process process = processBuilder.start();
    String output;
    try (InputStream input = process.getInputStream();
         ByteArrayOutputStream bytes = new ByteArrayOutputStream()) {
      input.transferTo(bytes);
      output = bytes.toString(StandardCharsets.UTF_8.name()).trim();
    }
    int exitCode = process.waitFor();
    if (exitCode != 0) {
      throw new IllegalStateException("firtool-resolver failed with exit code " + exitCode);
    }
    if (output.isEmpty()) {
      throw new IllegalStateException("firtool-resolver did not return a firtool path");
    }

    String[] outputLines = output.split("\\R");
    Path source = Paths.get(outputLines[outputLines.length - 1]);
    Path destination = Paths.get(args[0]);
    Files.createDirectories(destination.getParent());
    Files.copy(source, destination, StandardCopyOption.REPLACE_EXISTING);
    File destinationFile = destination.toFile();
    if (!destinationFile.setExecutable(true, false) && !destinationFile.canExecute()) {
      throw new IllegalStateException("Unable to make firtool executable: " + destination);
    }

    System.out.println("Resolved firtool " + version + " for the configured Chisel artifact");
  }
}

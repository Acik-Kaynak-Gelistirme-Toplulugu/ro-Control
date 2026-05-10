#include "commandrunner.h"

#include <QElapsedTimer>
#include <QFileInfo>
#include <QProcess>
#include <QStandardPaths>
#include <QThread>

#include <algorithm>

CommandRunner::CommandRunner(QObject *parent) : QObject(parent) {}

CommandRunner::Result CommandRunner::run(const QString &program,
                                         const QStringList &args) {
  return run(program, args, RunOptions{});
}

CommandRunner::Result CommandRunner::run(const QString &program,
                                         const QStringList &args,
                                         const RunOptions &options) {
  const int totalAttempts = std::max(1, options.retries + 1);
  Result lastResult{.exitCode = -1, .stdout = {}, .stderr = {}, .attempt = 1};

  for (int attempt = 1; attempt <= totalAttempts; ++attempt) {
    lastResult = runOnce(program, args, options, attempt);

    if (lastResult.success() || attempt == totalAttempts) {
      break;
    }

    if (options.retryDelayMs > 0) {
      QThread::msleep(static_cast<unsigned long>(options.retryDelayMs));
    }
  }

  return lastResult;
}

QString CommandRunner::overrideEnvironmentVariableName(const QString &program) {
  QString normalized = program.toUpper();
  normalized.replace(QLatin1Char('-'), QLatin1Char('_'));
  normalized.replace(QLatin1Char('.'), QLatin1Char('_'));
  normalized.replace(QLatin1Char('/'), QLatin1Char('_'));
  return QStringLiteral("RO_CONTROL_COMMAND_%1").arg(normalized);
}

QString CommandRunner::resolveProgramPath(const QString &program) {
  if (program.isEmpty()) {
    return {};
  }

  const QString overridePath =
      qEnvironmentVariable(overrideEnvironmentVariableName(program).toUtf8())
          .trimmed();
  if (!overridePath.isEmpty()) {
    return overridePath;
  }

  if (program.contains(QLatin1Char('/'))) {
    return program;
  }

  return QStandardPaths::findExecutable(program);
}

QString CommandRunner::resolveProgram(const QString &program) const {
  return resolveProgramPath(program);
}

CommandRunner::Result CommandRunner::runOnce(const QString &program,
                                             const QStringList &args,
                                             const RunOptions &options,
                                             int attempt) {
  QProcess process;
  QByteArray stdoutBuffer;
  QByteArray stderrBuffer;
  QByteArray stdoutLineBuffer;
  QByteArray stderrLineBuffer;
  QElapsedTimer timer;

  auto emitBufferedLines = [](QByteArray &lineBuffer, const QByteArray &chunk,
                              const auto &emitLine) {
    lineBuffer.append(chunk);

    qsizetype newlineIndex = lineBuffer.indexOf('\n');
    while (newlineIndex >= 0) {
      const QString line =
          QString::fromUtf8(lineBuffer.left(newlineIndex)).trimmed();
      if (!line.isEmpty()) {
        emitLine(line);
      }
      lineBuffer.remove(0, newlineIndex + 1);
      newlineIndex = lineBuffer.indexOf('\n');
    }
  };

  auto flushBufferedLine = [](QByteArray &lineBuffer, const auto &emitLine) {
    const QString line = QString::fromUtf8(lineBuffer).trimmed();
    if (!line.isEmpty()) {
      emitLine(line);
    }
    lineBuffer.clear();
  };

  emit commandStarted(program, args, attempt);
  timer.start();

  const QString resolvedProgram = resolveProgram(program);
  if (resolvedProgram.isEmpty()) {
    const Result result{
        .exitCode = -1,
        .stdout = {},
        .stderr = QStringLiteral("Executable not found: %1").arg(program),
        .attempt = attempt,
    };
    emit commandFinished(program, result.exitCode, attempt,
                         static_cast<int>(timer.elapsed()));
    return result;
  }

  // Stdout'u anlik olarak yayinla ve sonucu korumak icin buffer'a biriktir.
  connect(&process, &QProcess::readyReadStandardOutput, this, [&]() {
    const QByteArray chunk = process.readAllStandardOutput();
    stdoutBuffer.append(chunk);
    emitBufferedLines(stdoutLineBuffer, chunk,
                      [this](const QString &line) { emit outputLine(line); });
  });

  connect(&process, &QProcess::readyReadStandardError, this, [&]() {
    const QByteArray chunk = process.readAllStandardError();
    stderrBuffer.append(chunk);
    emitBufferedLines(stderrLineBuffer, chunk,
                      [this](const QString &line) { emit errorLine(line); });
  });

  process.start(resolvedProgram, args);

  if (!process.waitForStarted(options.startTimeoutMs)) {
    const Result result{
        .exitCode = -1,
        .stdout = {},
        .stderr = QStringLiteral("Failed to start: %1").arg(program),
        .attempt = attempt,
    };
    emit commandFinished(program, result.exitCode, attempt,
                         static_cast<int>(timer.elapsed()));
    return result;
  }

  if (!options.stdinData.isEmpty()) {
    process.write(options.stdinData);
  }
  process.closeWriteChannel();

  bool finished = false;
  const int pollIntervalMs = 100;
  while (true) {
    if (options.cancelRequested &&
        options.cancelRequested->load(std::memory_order_relaxed)) {
      process.terminate();
      if (!process.waitForFinished(1500)) {
        process.kill();
        process.waitForFinished(1000);
      }
      flushBufferedLine(stdoutLineBuffer,
                        [this](const QString &line) { emit outputLine(line); });
      flushBufferedLine(stderrLineBuffer,
                        [this](const QString &line) { emit errorLine(line); });
      const Result result{
          .exitCode = -3,
          .stdout = QString::fromUtf8(stdoutBuffer),
          .stderr = QStringLiteral("Command canceled by user: %1").arg(program),
          .attempt = attempt,
      };
      emit commandFinished(program, result.exitCode, attempt,
                           static_cast<int>(timer.elapsed()));
      return result;
    }

    const int elapsedMs = static_cast<int>(timer.elapsed());
    if (options.timeoutMs >= 0 && elapsedMs >= options.timeoutMs) {
      finished = false;
      break;
    }

    const int waitMs =
        options.timeoutMs < 0
            ? pollIntervalMs
            : std::min(pollIntervalMs, options.timeoutMs - elapsedMs);
    finished = process.waitForFinished(std::max(0, waitMs));
    if (finished) {
      break;
    }
  }

  if (!finished) {
    process.kill();
    process.waitForFinished(1000);
    flushBufferedLine(stdoutLineBuffer,
                      [this](const QString &line) { emit outputLine(line); });
    flushBufferedLine(stderrLineBuffer,
                      [this](const QString &line) { emit errorLine(line); });
    const Result result{
        .exitCode = -2,
        .stdout = QString::fromUtf8(stdoutBuffer),
        .stderr = QStringLiteral("Timed out: %1").arg(program),
        .attempt = attempt,
    };
    emit commandFinished(program, result.exitCode, attempt,
                         static_cast<int>(timer.elapsed()));
    return result;
  }

  const QByteArray remainingStdout = process.readAllStandardOutput();
  const QByteArray remainingStderr = process.readAllStandardError();
  stdoutBuffer.append(remainingStdout);
  stderrBuffer.append(remainingStderr);
  emitBufferedLines(stdoutLineBuffer, remainingStdout,
                    [this](const QString &line) { emit outputLine(line); });
  emitBufferedLines(stderrLineBuffer, remainingStderr,
                    [this](const QString &line) { emit errorLine(line); });
  flushBufferedLine(stdoutLineBuffer,
                    [this](const QString &line) { emit outputLine(line); });
  flushBufferedLine(stderrLineBuffer,
                    [this](const QString &line) { emit errorLine(line); });

  const Result result{
      .exitCode = process.exitCode(),
      .stdout = QString::fromUtf8(stdoutBuffer),
      .stderr = QString::fromUtf8(stderrBuffer),
      .attempt = attempt,
  };

  emit commandFinished(program, result.exitCode, attempt,
                       static_cast<int>(timer.elapsed()));
  return result;
}

CommandRunner::Result CommandRunner::runAsRoot(const QString &program,
                                               const QStringList &args) {
  return runAsRoot(program, args, RunOptions{});
}

CommandRunner::Result CommandRunner::runAsRoot(const QString &program,
                                               const QStringList &args,
                                               const RunOptions &options) {
  QStringList pkexecArgs;
  pkexecArgs << helperPath() << program << args;
  return run(QStringLiteral("pkexec"), pkexecArgs, options);
}

CommandRunner::Result
CommandRunner::runAsRootBatch(const QList<RootCommand> &commands) {
  return runAsRootBatch(commands, RunOptions{});
}

CommandRunner::Result
CommandRunner::runAsRootBatch(const QList<RootCommand> &commands,
                              const RunOptions &options) {
  if (commands.isEmpty()) {
    return Result{.exitCode = -1,
                  .stdout = {},
                  .stderr = QStringLiteral("No privileged commands provided."),
                  .attempt = 1};
  }

  QByteArray stdinData;
  for (const RootCommand &command : commands) {
    if (command.program.trimmed().isEmpty()) {
      return Result{.exitCode = -1,
                    .stdout = {},
                    .stderr = QStringLiteral("Empty privileged command."),
                    .attempt = 1};
    }

    stdinData += command.program.toUtf8();
    for (const QString &arg : command.args) {
      if (arg.contains(QLatin1Char('\t')) ||
          arg.contains(QLatin1Char('\n'))) {
        return Result{.exitCode = -1,
                      .stdout = {},
                      .stderr = QStringLiteral(
                          "Privileged command arguments cannot contain tabs or "
                          "newlines."),
                      .attempt = 1};
      }
      stdinData += '\t';
      stdinData += arg.toUtf8();
    }
    stdinData += '\n';
  }

  RunOptions batchOptions = options;
  batchOptions.stdinData = stdinData;

  QStringList pkexecArgs;
  pkexecArgs << helperPath() << QStringLiteral("--batch");
  return run(QStringLiteral("pkexec"), pkexecArgs, batchOptions);
}

QString CommandRunner::helperPath() {
  QString path = QStringLiteral(RO_CONTROL_HELPER_BUILD_PATH);
  if (!QFileInfo::exists(path)) {
    path = QStringLiteral(RO_CONTROL_HELPER_INSTALL_PATH);
  }
  return path;
}

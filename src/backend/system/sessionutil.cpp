#include "sessionutil.h"

#include "commandrunner.h"

#include <QtGlobal>

namespace SessionUtil {
namespace {

QString normalizeSessionType(const QString &value) {
  const QString normalized = value.trimmed().toLower();
  if (normalized == QStringLiteral("wayland")) {
    return normalized;
  }
  return {};
}

SessionInfo infoFromType(const QString &type, const QString &source,
                         const QString &evidence, bool certain = true) {
  SessionInfo info;
  info.type = type;
  info.source = source;
  info.evidence << evidence;
  info.isCertain = certain;
  return info;
}

QString loginctlSessionType(CommandRunner &runner, const QString &sessionId) {
  if (sessionId.trimmed().isEmpty()) {
    return {};
  }

  const auto result =
      runner.run(QStringLiteral("loginctl"),
                 {QStringLiteral("show-session"), sessionId.trimmed(),
                  QStringLiteral("-p"), QStringLiteral("Type"),
                  QStringLiteral("--value")});

  if (!result.success()) {
    return {};
  }

  return normalizeSessionType(result.stdout);
}

QString loginctlDisplaySession(CommandRunner &runner) {
  const QString userName = qEnvironmentVariable("USER").trimmed();
  if (userName.isEmpty()) {
    return {};
  }

  const auto result =
      runner.run(QStringLiteral("loginctl"),
                 {QStringLiteral("show-user"), userName, QStringLiteral("-p"),
                  QStringLiteral("Display"), QStringLiteral("--value")});

  return result.success() ? result.stdout.trimmed() : QString();
}

QString loginctlFirstGraphicalSession(CommandRunner &runner) {
  const QString userName = qEnvironmentVariable("USER").trimmed();
  const auto result =
      runner.run(QStringLiteral("loginctl"), {QStringLiteral("list-sessions"),
                                              QStringLiteral("--no-legend")});

  if (!result.success()) {
    return {};
  }

  const QStringList lines =
      result.stdout.split(QLatin1Char('\n'), Qt::SkipEmptyParts);
  for (const QString &line : lines) {
    const QStringList parts = line.simplified().split(QLatin1Char(' '));
    if (parts.size() < 3) {
      continue;
    }

    const QString sessionId = parts.at(0);
    const QString sessionUser = parts.at(2);
    if (!userName.isEmpty() && sessionUser != userName) {
      continue;
    }

    const QString type = loginctlSessionType(runner, sessionId);
    if (!type.isEmpty()) {
      return sessionId;
    }
  }

  return {};
}

} // namespace

SessionInfo detectSessionInfo() {
  const QString envType =
      normalizeSessionType(qEnvironmentVariable("XDG_SESSION_TYPE"));
  if (!envType.isEmpty()) {
    return infoFromType(envType, QStringLiteral("XDG_SESSION_TYPE"),
                        QStringLiteral("XDG_SESSION_TYPE=%1").arg(envType));
  }

  CommandRunner runner;
  const QString currentSessionId =
      qEnvironmentVariable("XDG_SESSION_ID").trimmed();
  QString type = loginctlSessionType(runner, currentSessionId);
  if (!type.isEmpty()) {
    return infoFromType(
        type, QStringLiteral("loginctl current session"),
        QStringLiteral("XDG_SESSION_ID=%1").arg(currentSessionId));
  }

  const QString displaySessionId = loginctlDisplaySession(runner);
  type = loginctlSessionType(runner, displaySessionId);
  if (!type.isEmpty()) {
    return infoFromType(type, QStringLiteral("loginctl display session"),
                        QStringLiteral("Display=%1").arg(displaySessionId));
  }

  const QString graphicalSessionId = loginctlFirstGraphicalSession(runner);
  type = loginctlSessionType(runner, graphicalSessionId);
  if (!type.isEmpty()) {
    return infoFromType(type, QStringLiteral("loginctl session list"),
                        QStringLiteral("Session=%1").arg(graphicalSessionId));
  }

  const bool hasWaylandDisplay =
      !qEnvironmentVariable("WAYLAND_DISPLAY").trimmed().isEmpty();
  if (hasWaylandDisplay) {
    return infoFromType(QStringLiteral("wayland"),
                        QStringLiteral("WAYLAND_DISPLAY"),
                        QStringLiteral("WAYLAND_DISPLAY is set"), false);
  }

  const QString qtPlatform =
      qEnvironmentVariable("QT_QPA_PLATFORM").trimmed().toLower();
  if (qtPlatform.contains(QStringLiteral("wayland"))) {
    return infoFromType(
        QStringLiteral("wayland"), QStringLiteral("QT_QPA_PLATFORM"),
        QStringLiteral("QT_QPA_PLATFORM=%1").arg(qtPlatform), false);
  }
  SessionInfo unknown;
  unknown.evidence << QStringLiteral(
      "No reliable session signal was available");
  return unknown;
}

QString detectSessionType() { return detectSessionInfo().type; }

} // namespace SessionUtil

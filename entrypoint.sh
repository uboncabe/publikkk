#!/bin/sh
set -e

# Entrypoint wrapper: ensure plugins directory exists and try runtime download of youtube-source plugin
# This runs before Lavalink starts so PluginManager won't fail due to missing/empty jars.

PLUGIN_PATH="./plugins/youtube-source-plugin.jar"
PLUGIN_URL="https://github.com/lavalink-devs/youtube-source/releases/latest/download/youtube-source-plugin.jar"

mkdir -p ./plugins

if [ ! -s "$PLUGIN_PATH" ]; then
  echo "⏳ Plugin not present at $PLUGIN_PATH, attempting runtime download..."
  if curl -fSL "$PLUGIN_URL" -o /tmp/youtube-source-plugin.jar; then
    if [ -s /tmp/youtube-source-plugin.jar ]; then
      mv /tmp/youtube-source-plugin.jar "$PLUGIN_PATH"
      echo "✅ youtube-source plugin downloaded to $PLUGIN_PATH"
    else
      echo "⚠️ downloaded plugin file is empty, removing /tmp/youtube-source-plugin.jar"
      rm -f /tmp/youtube-source-plugin.jar || true
    fi
  else
    echo "⚠️ runtime download of youtube-source plugin failed (network/HTTP error)"
  fi
else
  echo "✅ plugin already present at $PLUGIN_PATH"
fi

# Start Lavalink
exec java -jar Lavalink.jar

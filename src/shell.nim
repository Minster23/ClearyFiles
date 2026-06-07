import std/os
import std/strutils
import reader

type
  ProgressInfo* = object
    total*: int
    done*: int
    running*: bool
    message*: string

var progress* {.threadvar.}: ProgressInfo

proc resetProgress*() =
  progress.total = 0
  progress.done = 0
  progress.running = false
  progress.message = "Ready."

proc getTargetFiles(targetDir: string, configs: seq[ConfigItem]): seq[(string, string)] =
  for filePath in walkFiles(targetDir / "*"):
    let fileExt = splitFile(filePath).ext.toLowerAscii()

    for cfg in configs:
      for ext in cfg.ext:
        if fileExt == normalizeExt(ext):
          result.add((filePath, cfg.dir))

proc categorizeFolder*(targetDir: string) =
  progress.running = true
  progress.message = "Scanning files..."
  progress.total = 0
  progress.done = 0

  let configs = loadConfig()
  let files = getTargetFiles(targetDir, configs)

  progress.total = files.len
  progress.message = "Categorizing..."

  if files.len == 0:
    progress.running = false
    progress.message = "No matching files."
    return

  for item in files:
    let filePath = item[0]
    let folderName = item[1]

    let outputDir = targetDir / folderName
    createDir(outputDir)

    let fileName = extractFilename(filePath)
    let outputPath = outputDir / fileName

    try:
      moveFile(filePath, outputPath)
    except OSError:
      discard

    inc progress.done

  progress.running = false
  progress.message = "Done."

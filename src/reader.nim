import std/json
import std/strutils
import std/os

const configPath* = "dir.json"

type
  ConfigItem* = object
    dir*: string
    ext*: seq[string]

proc ensureConfigFile() =
  if not fileExists(configPath):
    writeFile(configPath, "[]")

proc normalizeExt*(ext: string): string =
  let e = ext.strip().toLowerAscii()
  if e.len == 0:
    return ""

  if e.startsWith("."):
    return e

  return "." & e

proc loadConfig*(): seq[ConfigItem] =
  ensureConfigFile()

  let raw = readFile(configPath)

  if raw.strip().len == 0:
    return @[]

  let node = parseJson(raw)

  for item in node:
    var cfg: ConfigItem

    cfg.dir = item["dir"].getStr()

    for e in item["ext"]:
      let ext = normalizeExt(e.getStr())
      if ext.len > 0:
        cfg.ext.add(ext)

    result.add(cfg)

proc saveConfig*(configs: seq[ConfigItem]) =
  var arr = newJArray()

  for cfg in configs:
    var obj = newJObject()
    obj["dir"] = newJString(cfg.dir)

    var extArr = newJArray()
    for e in cfg.ext:
      let ext = normalizeExt(e)
      if ext.len > 0:
        extArr.add(newJString(ext))

    obj["ext"] = extArr
    arr.add(obj)

  writeFile(configPath, arr.pretty())

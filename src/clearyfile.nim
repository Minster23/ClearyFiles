import nigui
import std/strutils
import std/os
import reader
import shell

app.init()

var configs = loadConfig()

var worker: Thread[string]
var hasWorker = false

var window = newWindow("Cleary Files")
window.width = 720.scaleToDpi
window.height = 620.scaleToDpi

var root = newLayoutContainer(Layout_Vertical)
root.padding = 12
window.add(root)

var title = newLabel("Cleary Files")
root.add(title)

var targetDir = newTextBox()
targetDir.placeholder = "Target directory path..."
root.add(targetDir)

var categorizeButton = newButton("Categorize")
root.add(categorizeButton)

var progressBar = newProgressBar()
progressBar.value = 0.0
root.add(progressBar)

var mainStatusLabel = newLabel("Ready.")
root.add(mainStatusLabel)

var showConfig = newCheckbox("Edit Config")
root.add(showConfig)

var configPanel = newLayoutContainer(Layout_Vertical)
configPanel.visible = false
root.add(configPanel)

var listContainer = newLayoutContainer(Layout_Vertical)
configPanel.add(listContainer)

var formTitle = newLabel("Add New Config")
configPanel.add(formTitle)

var dirInput = newTextBox()
dirInput.placeholder = "Folder name, contoh: gambar"
configPanel.add(dirInput)

var extInput = newTextBox()
extInput.placeholder = "Extensions, contoh: .png, .jpg, .jpeg"
configPanel.add(extInput)

var buttonRow = newLayoutContainer(Layout_Horizontal)
configPanel.add(buttonRow)

var addButton = newButton("Add")
var saveButton = newButton("Save Config")
var reloadButton = newButton("Reload")

buttonRow.add(addButton)
buttonRow.add(saveButton)
buttonRow.add(reloadButton)

var statusLabel = newLabel("")
configPanel.add(statusLabel)

proc categorizeThread(target: string) {.thread.} =
  categorizeFolder(target)

proc parseExtensions(text: string): seq[string] =
  for part in text.split(","):
    let ext = normalizeExt(part)

    if ext.len > 0:
      result.add(ext)

proc refreshList()

proc makeRow(index: int, cfg: ConfigItem): LayoutContainer =
  var row = newLayoutContainer(Layout_Horizontal)

  var dirLabel = newLabel(cfg.dir)
  var extLabel = newLabel(cfg.ext.join(", "))
  var deleteButton = newButton("Delete")

  deleteButton.onClick = proc(event: ClickEvent) =
    configs.delete(index)
    refreshList()
    statusLabel.text = "Item deleted. Jangan lupa Save Config."

  row.add(dirLabel)
  row.add(extLabel)
  row.add(deleteButton)

  return row

proc refreshList() =
  var header = newLayoutContainer(Layout_Horizontal)
  header.add(newLabel("Dir"))
  header.add(newLabel("Extension"))
  header.add(newLabel("Action"))
  listContainer.add(header)

  for i, cfg in configs:
    listContainer.add(makeRow(i, cfg))

categorizeButton.onClick = proc(event: ClickEvent) =
  let path = targetDir.text.strip()

  if path.len == 0:
    mainStatusLabel.text = "Target directory kosong."
    return

  if not dirExists(path):
    mainStatusLabel.text = "Target directory tidak ditemukan."
    return

  if progress.running:
    mainStatusLabel.text = "Categorize masih berjalan."
    return

  saveConfig(configs)
  resetProgress()

  progressBar.value = 0.0
  mainStatusLabel.text = "Starting..."
  categorizeButton.enabled = false

  hasWorker = true
  createThread(worker, categorizeThread, path)

showConfig.onClick = proc(event: ClickEvent) =
  configPanel.visible = showConfig.checked

addButton.onClick = proc(event: ClickEvent) =
  let dirName = dirInput.text.strip()
  let extensions = parseExtensions(extInput.text)

  if dirName.len == 0:
    statusLabel.text = "Folder name masih kosong."
    return

  if extensions.len == 0:
    statusLabel.text = "Extension masih kosong."
    return

  configs.add(ConfigItem(dir: dirName, ext: extensions))

  dirInput.text = ""
  extInput.text = ""

  refreshList()
  statusLabel.text = "Item added. Jangan lupa Save Config."

saveButton.onClick = proc(event: ClickEvent) =
  saveConfig(configs)
  statusLabel.text = "Config saved."

reloadButton.onClick = proc(event: ClickEvent) =
  configs = loadConfig()
  refreshList()
  statusLabel.text = "Config reloaded."

discard startRepeatingTimer(100, proc(event: TimerEvent) =
  if progress.total > 0:
    let value = progress.done.float / progress.total.float
    progressBar.value = value
    mainStatusLabel.text = $progress.done & " / " & $progress.total & " files"

  if hasWorker and not progress.running:
    if progress.total > 0:
      progressBar.value = 1.0
    else:
      progressBar.value = 0.0

    mainStatusLabel.text = progress.message
    categorizeButton.enabled = true

    joinThread(worker)
    hasWorker = false
)

refreshList()

window.show()
app.run()

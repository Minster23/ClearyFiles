# begin Nimble config (version 2)
when withDir(thisDir(), system.fileExists("nimble.paths")):
  include "nimble.paths"
# end Nimble config

# Flag untuk menyembunyikan CMD dan membuat aplikasi jadi GUI
switch("app", "gui")

# Flag untuk menyalakan Threads
switch("threads", "on")

# Flag optimasi produksi (opsional, bisa ditulis di sini atau saat build)
switch("define", "danger")

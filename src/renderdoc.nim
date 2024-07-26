import std/dynlib, vulkan, renderdoc_app

when defined(android):
  const rDocDLL = "libVkLayer_GLES_RenderDoc.so"
elif defined(linux):
  const rDocDLL = "librenderdoc.so"
elif defined(windows):
  const rDocDLL = "renderdoc.dll"
elif defined(macosx):
  const rDocDLL = "librenderdoc.dylib"
else:
  {.error: "RenderDoc integration not implemented on this platform".}

var
  initialized = false
  rDocAPI: ptr RENDERDOC_API_1_6_0 = nil
  rDocGetAPI: pRENDERDOC_GetAPI

proc getRDocAPI(): ptr RENDERDOC_API_1_6_0 =
  if initialized:
    return rDocAPI
  initialized = true
  let rDocHandleDLL = loadLib(rDocDLL)
  if isNil(rDocHandleDLL):
    raise newException(LibraryError, "Failed to load " & rDocDLL)
  rDocGetAPI = cast[pRENDERDOC_GetAPI](checkedSymAddr(rDocHandleDLL, "RENDERDOC_GetAPI"))
  let ret = rDocGetAPI(eRENDERDOC_API_Version_1_6_0, cast[ptr pointer](addr rDocAPI))
  if ret != 1:
    rDocAPI = nil
    raise newException(LibraryError, "RenderDoc initialization failed")
  result = rDocAPI

# proc rDocInit*() =
#   rDocAPI = getRDocAPI()

import std/macros

macro wrapLibLoading(f: untyped): untyped =
  f.expectKind nnkStmtList
  result = newStmtList()

  template loadLib: untyped =
    if not initialized:
      rDocAPI = getRDocAPI()

  for child in f.children:
    if child.kind == nnkCommentStmt:
      continue
    child.expectKind nnkProcDef
    var rDocProc = copy child
    rDocProc.body.insert(0, getAst(loadLib()))
    result.add rDocProc

wrapLibLoading:
  proc startFrameCapture*(instance: VkInstance) =
    let device = RENDERDOC_DEVICEPOINTER_FROM_VKINSTANCE(instance)
    rDocAPI.StartFrameCapture(device, nil)

  proc endFrameCapture*(instance: VkInstance) =
    let device = RENDERDOC_DEVICEPOINTER_FROM_VKINSTANCE(instance)
    discard rDocAPI.EndFrameCapture(device, nil)

  proc setCaptureTitle*(title: string) =
    rDocAPI.SetCaptureTitle(title.cstring)

  proc discardFrameCapture*(device: RENDERDOC_DevicePointer, wndHandle: RENDERDOC_WindowHandle): bool =
    rDocAPI.DiscardFrameCapture(device, wndHandle) == 1

  proc isFrameCapturing*(): bool =
    rDocAPI.IsFrameCapturing() == 1

  proc triggerCapture*() =
    rDocAPI.TriggerCapture()

  proc triggerMultiFrameCapture*(numFrames: uint32) =
    rDocAPI.TriggerMultiFrameCapture(numFrames)

  proc setActiveWindow*(device: RENDERDOC_DevicePointer, wndHandle: RENDERDOC_WindowHandle) =
    rDocAPI.SetActiveWindow(device, wndHandle)

  proc showReplayUI*(): bool =
    rDocAPI.ShowReplayUI() == 1

  proc setCaptureFileComments(filePath, comments: string) =
    rDocAPI.SetCaptureFileComments(filePath.cstring, comments.cstring)

  proc getCapture*(idx: uint32, filename: string, pathlength: out uint32, timestamp: out uint64): bool =
    rDocAPI.GetCapture(idx, filename.cstring, pathlength.addr, timestamp.addr) == 1

  proc getNumCaptures*(): uint32 =
    rDocAPI.GetNumCaptures()

  proc setCaptureFilePathTemplate*(pathtemplate: string) =
    rDocAPI.SetCaptureFilePathTemplate(pathtemplate.cstring)

  proc getCaptureFilePathTemplate*(): string =
    $rDocAPI.GetCaptureFilePathTemplate()

  proc unloadCrashHandler*() =
    rDocAPI.UnloadCrashHandler()

  proc removeHooks*() =
    rDocAPI.RemoveHooks()

  proc maskOverlayBits*(And, Or: uint32) =
    rDocAPI.MaskOverlayBits(And, Or)

  proc getOverlayBits*(): uint32 =
    rDocAPI.GetOverlayBits()

  proc setCaptureKeys*(keys: openarray[RENDERDOC_InputButton]) =
    rDocAPI.SetCaptureKeys(cast[ptr[RENDERDOC_InputButton]](keys), keys.len.cint)

  proc setFocusToggleKeys*(keys: openarray[RENDERDOC_InputButton]) =
    rDocAPI.SetFocusToggleKeys(cast[ptr[RENDERDOC_InputButton]](keys), keys.len.cint)

  proc getCaptureOptionF32*(opt: RENDERDOC_CaptureOption): float32 =
    rDocAPI.GetCaptureOptionF32(opt)

  proc getCaptureOptionU32*(opt: RENDERDOC_CaptureOption): uint32 =
    rDocAPI.GetCaptureOptionU32(opt)

  proc setCaptureOptionU32*(opt: RENDERDOC_CaptureOption, val: uint32): bool =
    rDocAPI.SetCaptureOptionU32(opt, val) == 1

  proc setCaptureOptionF32*(opt: RENDERDOC_CaptureOption, val: float32): bool =
    rDocAPI.SetCaptureOptionF32(opt, val) == 1

#include "flutter_window.h"

#include <optional>

#include "flutter/generated_plugin_registrant.h"

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }

  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  HRESULT hr = OleInitialize(nullptr);
  is_ole_init_ = SUCCEEDED(hr) || hr == RPC_E_CHANGED_MODE;

  if (is_ole_init_ && SUCCEEDED(RegisterDragDrop(flutter_controller_->view()->GetNativeWindow(), this))) {
    hwnd_registered_ = flutter_controller_->view()->GetNativeWindow();
  }

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  if (hwnd_registered_) {
    RevokeDragDrop(hwnd_registered_);
    hwnd_registered_ = nullptr;
  }

  if (is_ole_init_) {
    OleUninitialize();
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}

HRESULT STDMETHODCALLTYPE FlutterWindow::QueryInterface(REFIID riid, void **ppv) {

  if (riid == IID_IUnknown || riid == IID_IDropTarget) {
    *ppv = static_cast<IDropTarget*>(this);
    AddRef();

    return S_OK;
  }

  return E_NOINTERFACE;
}

ULONG STDMETHODCALLTYPE FlutterWindow::AddRef() {
  return InterlockedIncrement(&ref_count_);
}

ULONG STDMETHODCALLTYPE FlutterWindow::Release() {
  return InterlockedDecrement(&ref_count_);
}

HRESULT __stdcall FlutterWindow::DragEnter(IDataObject *, DWORD, POINTL, DWORD *) { return S_OK; }

HRESULT __stdcall FlutterWindow::DragOver(DWORD, POINTL, DWORD *) { return S_OK; }

HRESULT __stdcall FlutterWindow::DragLeave() { return S_OK; }

HRESULT __stdcall FlutterWindow::Drop(IDataObject *, DWORD, POINTL, DWORD *) { return S_OK; }
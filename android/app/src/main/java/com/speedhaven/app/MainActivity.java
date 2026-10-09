package com.speedhaven.app;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.util.Base64;
import android.webkit.JavascriptInterface;
import android.webkit.ValueCallback;
import android.webkit.WebChromeClient;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import java.io.OutputStream;

/** Offline-first Android shell for the Polya writer notebook. */
public final class MainActivity extends Activity {
    private static final int FILE_CHOOSER_REQUEST = 4101;
    private static final int SAVE_FILE_REQUEST = 4102;
    private ValueCallback<Uri[]> pendingFileCallback;
    private String pendingName = "writing.txt";
    private String pendingMime = "text/plain";
    private String pendingBase64 = "";

    @SuppressLint("SetJavaScriptEnabled")
    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        WebView webView = new WebView(this);
        WebSettings settings = webView.getSettings();
        settings.setJavaScriptEnabled(true);
        settings.setDomStorageEnabled(true);
        settings.setAllowFileAccess(true);
        settings.setAllowContentAccess(true);
        webView.addJavascriptInterface(new SaveBridge(), "AndroidBridge");
        webView.setWebViewClient(new WebViewClient());
        webView.setWebChromeClient(new WebChromeClient() {
            @Override public boolean onShowFileChooser(WebView view, ValueCallback<Uri[]> callback, FileChooserParams params) {
                if (pendingFileCallback != null) pendingFileCallback.onReceiveValue(null);
                pendingFileCallback = callback;
                Intent pick = new Intent(Intent.ACTION_OPEN_DOCUMENT);
                pick.addCategory(Intent.CATEGORY_OPENABLE);
                pick.setType("*/*");
                pick.putExtra(Intent.EXTRA_ALLOW_MULTIPLE, false);
                try { startActivityForResult(pick, FILE_CHOOSER_REQUEST); }
                catch (Exception error) {
                    pendingFileCallback.onReceiveValue(null);
                    pendingFileCallback = null;
                }
                return true;
            }
        });
        webView.loadUrl("file:///android_asset/index.html");
        setContentView(webView);
    }

    private final class SaveBridge {
        @JavascriptInterface
        public void saveFile(String name, String mime, String base64) {
            runOnUiThread(() -> {
                pendingName = name == null || name.trim().isEmpty() ? "writing.txt" : name.replaceAll("[\\\\/:*?\"<>|]", "_");
                pendingMime = mime == null || mime.isEmpty() ? "text/plain" : mime;
                pendingBase64 = base64 == null ? "" : base64;
                Intent save = new Intent(Intent.ACTION_CREATE_DOCUMENT);
                save.addCategory(Intent.CATEGORY_OPENABLE);
                save.setType(pendingMime);
                save.putExtra(Intent.EXTRA_TITLE, pendingName);
                startActivityForResult(save, SAVE_FILE_REQUEST);
            });
        }
    }

    @Override protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == FILE_CHOOSER_REQUEST) {
            if (pendingFileCallback != null) {
                Uri[] result = resultCode == RESULT_OK && data != null && data.getData() != null ? new Uri[]{data.getData()} : null;
                pendingFileCallback.onReceiveValue(result);
                pendingFileCallback = null;
            }
            return;
        }
        if (requestCode == SAVE_FILE_REQUEST && resultCode == RESULT_OK && data != null && data.getData() != null) {
            try (OutputStream out = getContentResolver().openOutputStream(data.getData())) {
                if (out != null) out.write(Base64.decode(pendingBase64, Base64.DEFAULT));
            } catch (Exception error) {
                android.util.Log.e("PolyaNotebook", "Could not save exported document", error);
            } finally {
                pendingBase64 = "";
            }
        }
    }
}
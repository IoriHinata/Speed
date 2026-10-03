package com.speedhaven.app;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.webkit.ValueCallback;
import android.webkit.WebChromeClient;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;

/** Native Android shell. Game code remains the offline web bundle in assets. */
public final class MainActivity extends Activity {
    private static final int FILE_CHOOSER_REQUEST = 4101;
    private ValueCallback<Uri[]> pendingFileCallback;

    @SuppressLint("SetJavaScriptEnabled")
    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        WebView webView = new WebView(this);
        WebSettings settings = webView.getSettings();
        settings.setJavaScriptEnabled(true);
        settings.setDomStorageEnabled(true);
        settings.setAllowFileAccess(true);
        settings.setAllowContentAccess(true);
        webView.setWebViewClient(new WebViewClient());
        webView.setWebChromeClient(new WebChromeClient() {
            @Override public boolean onShowFileChooser(WebView view, ValueCallback<Uri[]> callback, FileChooserParams params) {
                if (pendingFileCallback != null) pendingFileCallback.onReceiveValue(null);
                pendingFileCallback = callback;
                Intent pick = new Intent(Intent.ACTION_OPEN_DOCUMENT);
                pick.addCategory(Intent.CATEGORY_OPENABLE);
                pick.setType("image/*");
                startActivityForResult(pick, FILE_CHOOSER_REQUEST);
                return true;
            }
        });
        webView.loadUrl("file:///android_asset/index.html");
        setContentView(webView);
    }

    @Override protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode != FILE_CHOOSER_REQUEST || pendingFileCallback == null) return;
        Uri[] result = resultCode == RESULT_OK && data != null && data.getData() != null ? new Uri[]{data.getData()} : null;
        pendingFileCallback.onReceiveValue(result);
        pendingFileCallback = null;
    }
}

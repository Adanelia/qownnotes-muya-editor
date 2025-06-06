import QtQuick 2.11
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.3
import QtWebEngine 1.10
import QtWebChannel 1.9

ApplicationWindow {
    id: root
    title: "Muya Markdown Editor"
    visible: false
    
    // 外部接口
    property var mainScript
    property string editorText: ""
    property int fontSize: mainScript.fontSize
    
    // 窗口尺寸设置
    width: 800
    height: 600
    
    // 窗口关闭处理
    onClosing: {
        mainScript.editorEnabled = false;
    }
    
    // 编辑器内容变化处理
    onEditorTextChanged: {
        if (webView.loadProgress === 100) {
            updateEditorContent(editorText);
        }
    }
    
    // 字体大小变化处理
    onFontSizeChanged: {
        if (webView.loadProgress === 100) {
            setFontSize(fontSize);
        }
    }
    
    // WebEngineView 用于承载 Muya 编辑器
    WebEngineView {
        id: webView
        anchors.fill: parent
        
        // 加载本地编辑器文件
        url: "file:///" + mainScript.scriptDirPath + "/muya-editor.html"
        
        // 初始化 WebChannel
        webChannel: WebChannel {
            id: webChannel
            registeredObjects: [qmlBridge]
        }
        
        // 页面加载完成时初始化编辑器
        onLoadProgressChanged: {
            if (loadProgress === 100) {
                // 设置字体大小
                setFontSize(fontSize);
                // 初始化编辑器内容
                updateEditorContent(editorText);
            }
        }
        
        // 禁用本地存储
        settings.localStorageEnabled: false
    }
    
    // QML 和 Web 之间的桥梁对象
    QtObject {
        id: qmlBridge
        WebChannel.id: "qmlBridge"
        
        // 从 Web 接收内容更新
        function contentChanged(content) {
            mainScript.updateNoteContent(content);
        }
        
        // 从 Web 接收状态更新
        function editorStatus(status) {
            console.log("Editor status:", status);
            
            if (status.startsWith("ready")) {
                // 编辑器准备就绪，更新内容
                updateEditorContent(editorText);
            } else if (status.startsWith("error")) {
                // 显示错误信息
                mainScript.log(status);
            }
        }
        
        // 调试输出
        function log(content) {
            mainScript.log(content);
        }
    }
    
    // 设置编辑器字体大小
    function setFontSize(size) {
        webView.runJavaScript(`
        if (window.muya) {
            muya.setFontSize(${size});
        } else {
            window.fontSize = ${size};
        }
        true;
        `);
    }
    
    // 更新编辑器内容
    function updateEditorContent(content) {
        if (!webView || !content) return;
        
        // 转义反引号
        const escapedContent = content.replace(/`/g, "\\`");
        
        // webView.runJavaScript(`
        // window.setMuyaContent('${escapedContent}');
        // true;
        // `);
        webView.runJavaScript('window.setMuyaContent(`' + escapedContent + '`);true;');
    }
    
    // 撤销操作
    function undo() {
        webView.runJavaScript("window.undo();");
    }
    
    // 重做操作
    function redo() {
        webView.runJavaScript("window.redo();");
    }
}

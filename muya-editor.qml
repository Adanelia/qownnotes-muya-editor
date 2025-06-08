import QtQml 2.0
import QOwnNotesTypes 1.0
import QtQuick 2.11
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.3

/**
 * Muya Markdown Editor for QOwnNotes
 */
QtObject {
    // 编辑器状态变量
    property bool editorEnabled: false
    property var editorWindow: null
    property int currentNoteId: 0
    
    // 本地路径
    property string scriptDirPath: ""  // 由QOwnNotes设置
    
    // 字体大小设置
    property int fontSize: 16
    
    // 注册脚本设置变量
    property variant settingsVariables: [
        {
            "identifier": "editorWidth",
            "name": "Editor Width",
            "description": "Default width of the editor window",
            "type": "integer",
            "default": 1000
        },
        {
            "identifier": "editorHeight",
            "name": "Editor Height",
            "description": "Default height of the editor window",
            "type": "integer",
            "default": 700
        },
        {
            "identifier": "fontSize",
            "name": "Font Size",
            "description": "Base font size for the editor",
            "type": "integer",
            "default": 16
        }
    ]
    
    // 脚本初始化
    function init() {
        log("Muya Editor initialized");
        
        // 注册自定义动作
        script.registerCustomAction(
            "toggleMuyaEditor",
            "Toggle Muya Editor",
            "Muya Editor",
            "x-office-document"
        );
    }
    
    // 自定义动作处理
    function customActionInvoked(identifier) {
        if (identifier === "toggleMuyaEditor") {
            toggleMuyaEditor();
        }
    }
    
    // 笔记打开时的处理
    function noteOpenedHook(note) {
        if (editorEnabled) {
            showEditor(note);
        }
    }
    
    // 切换编辑器状态
    function toggleMuyaEditor() {
        editorEnabled = !editorEnabled;
        
        if (editorEnabled) {
            showEditor(script.currentNote());
        } else if (editorWindow) {
            editorWindow.close();
            editorWindow.destroy();
            editorWindow = null;
        }
        
        log("Muya Editor " + (editorEnabled ? "enabled" : "disabled"));
    }
    
    // 显示编辑器窗口
    function showEditor(note) {
        if (!note) return;
        
        if (!editorWindow) {
            createEditorWindow();
        }
        
        currentNoteId = note.id;
        editorWindow.editorText = note.noteText;
        editorWindow.visible = true;
        editorWindow.requestActivate();
    }
    
    // 创建编辑器窗口
    function createEditorWindow() {
        var component = Qt.createComponent("muya-editor-window.qml");
        if (component.status === Component.Ready) {
            editorWindow = component.createObject(mainWindow, {
                mainScript: this,
                width: settingsVariables[0].default,
                height: settingsVariables[1].default
            });
            editorWindow.closing.connect(function() {
                editorEnabled = false;
            });
        } else {
            log("Error creating editor: " + component.errorString());
        }
    }
    
    // 从编辑器更新笔记内容
    function updateNoteContent(text) {
        if (!editorEnabled) return;
        
        var note = script.currentNote();
        if (note && note.id === currentNoteId && note.noteText !== text) {
            // 保存当前光标位置
            var cursorPosition = script.noteTextEditCursorPosition();
            var selectionStart = script.noteTextEditSelectionStart();
            var selectionEnd = script.noteTextEditSelectionEnd();
            
            // 更新内容
            script.noteTextEditSelectAll();
            script.noteTextEditWrite(text);
            
            // 恢复光标位置
            if (selectionStart !== selectionEnd) {
                script.noteTextEditSetSelection(selectionStart, selectionEnd);
            } else {
                script.noteTextEditSetCursorPosition(cursorPosition);
            }
        }
    }
    
    // 打印日志
    function log(text) {
        script.log(text);
    }
}

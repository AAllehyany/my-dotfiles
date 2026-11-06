import QtQuick
import Quickshell
import Quickshell.Services.Pam

// Checks the current user's password with boron/pam/password.conf.
// Same interface as the fake authenticators in lock-smoke.qml and lock-preview.qml.
Scope {
    id: root
    signal succeeded()
    signal failed(string message)
    property string pending: ""

    function start(password) {
        pending = password;
        if (!pam.start()) {
            pending = "";
            failed("couldn't start authentication");
        }
    }

    PamContext {
        id: pam
        configDirectory: Quickshell.shellPath("pam")
        config: "password.conf"
        onResponseRequiredChanged: {
            if (responseRequired && root.pending !== "") {
                respond(root.pending);
                root.pending = "";
            }
        }
        onCompleted: result => {
            root.pending = "";
            if (result === PamResult.Success) root.succeeded();
            else root.failed(result === PamResult.MaxTries ? "too many attempts" : "wrong password");
        }
        onError: error => {
            root.pending = "";
            root.failed("authentication error");
        }
    }
}

import QtQuick 2.0
import QtQuick.LocalStorage 2.0

Item {
    property var db : LocalStorage.openDatabaseSync("QContainers_DB", "1.0", "containers settings", 1000000)


    Component.onCompleted: {
        try {
            db.transaction(function (tx) {
                tx.executeSql('CREATE TABLE IF NOT EXISTS Containers (name TEXT,icon TEXT,portrait BOOL)')
            })
            console.log("DB created.")
        } catch (err) {
            console.log("Error creating table in database: " + err)
        };

    }

    function get_icon(name) {
        // get icon from container's name
        var r = ""

        db.transaction(function(tx) {
            // Show all added greetings
            var rs = tx.executeSql('SELECT * FROM Containers WHERE name = ?', [name])

            for (var i = 0; i < rs.rows.length; i++) {
                r = rs.rows.item(i).icon
            }
        })

        if (r == "image://theme/icon-m-computer"){
            return ""
        }
        return r
    }

    function set_icon(name, icon) {
        // change a container's icon
        db.transaction(function(tx) {

            // check if container exist in db
            var check = tx.executeSql('SELECT * FROM Containers WHERE name = ?', [name])

            if (check.rows.length > 0) {
                tx.executeSql('UPDATE Containers SET icon=? WHERE name = ?', [icon, name])
            } else {
                tx.executeSql('INSERT INTO Containers VALUES(?, ?, ?)', [ name, icon, false ])
            }


        })
        return true

    }

    function set_portrait(name, value){
        // set screen orientation, portrait true/false
        db.transaction(function(tx) {

            // check if container exist in db
            var check = tx.executeSql('SELECT * FROM Containers WHERE name = ?', [name])

            if (check.rows.length > 0) {
                tx.executeSql('UPDATE Containers SET portrait=? WHERE name = ?', [value, name])
            } else {
                tx.executeSql('INSERT INTO Containers VALUES(?, ?, ?)', [ name, "", value ])
            }


        })
        return true
    }

    function delete_container(name){
        // delete container config executed from "destroy container"
        db.transaction(function(tx) {

            // check if container exist in db
            var check = tx.executeSql('SELECT * FROM Containers WHERE name = ?', [name])

            if (check.rows.length > 0) {
                tx.executeSql('DELETE FROM Containers WHERE name = ?', [name])
            }

        })
        return true
    }
}

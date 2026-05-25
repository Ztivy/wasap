const {setGlobalOptions} = require("firebase-functions");
const {onRequest} = require("firebase-functions/https");
const logger = require("firebase-functions/logger");
setGlobalOptions({ maxInstances: 10 });

const admin = require('firebase-admin');
admin.initializeApp();

const firestore=admin.firestore();

exports.onUserStatusChange=functions.database().ref('/{uid}/active').onUpdate(
    async(Change,context)=>{
        const isActive= change.after.val();

        const firestoreRef = firestore.doc(`users/${context.params.uid}`);

        return firestoreRef.update({
            active:isActive,
            lastSeen: Date.now(),
        });
    }
);
   const admin = require('firebase-admin');
   const serviceAccount = require('../kavach-c9d5b-firebase-adminsdk-fbsvc-c00d19a13b.json');

   admin.initializeApp({
     credential: admin.credential.cert(serviceAccount)
   });

   const uid = 'TpNCuAqUFyMKLM8YK3ewzpMsIYJ3';

   admin.auth().setCustomUserClaims(uid, { admin: true })
     .then(() => {
       console.log('Admin claim set!');
       process.exit();
     })
     .catch(console.error);
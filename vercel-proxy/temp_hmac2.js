const crypto=require('crypto');
const qr='47045355';
const device='device123';
const ts=new Date().toISOString();
const msg=`${qr}|${device}|${ts}`;
const h=crypto.createHmac('sha256','dev_secret').update(msg).digest('hex');
console.log(JSON.stringify({qr,device,ts,msg,h}));

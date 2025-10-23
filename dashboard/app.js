const msg = document.getElementById('msg');
const loginBox = document.getElementById('loginBox');
const userInfo = document.getElementById('userInfo');
const userEmail = document.getElementById('userEmail');
const btnLogin = document.getElementById('btnLogin');
const btnLogout = document.getElementById('btnLogout');
const main = document.getElementById('main');
const eventsTable = document.getElementById('eventsTable');
const btnApply = document.getElementById('btnApply');
const btnClear = document.getElementById('btnClear');
const btnExport = document.getElementById('btnExport');
const filterUser = document.getElementById('filterUser');
const filterQR = document.getElementById('filterQR');

let unsubscribe = null;

btnLogin.addEventListener('click', async () => {
  const email = document.getElementById('email').value;
  const pass = document.getElementById('password').value;
  try {
    await firebase.auth().signInWithEmailAndPassword(email, pass);
  } catch (e) { msg.textContent = 'Error login: '+e.message }
});

btnLogout.addEventListener('click', async () => {
  await firebase.auth().signOut();
});

firebase.auth().onAuthStateChanged(async user => {
  if (!user) {
    loginBox.classList.remove('hidden');
    userInfo.classList.add('hidden');
    main.classList.add('hidden');
    msg.textContent = '';
    if (unsubscribe) { unsubscribe(); unsubscribe=null }
    return;
  }
  // check role in users collection
  const udoc = await db.collection('users').doc(user.uid).get();
  const role = udoc.exists ? udoc.data().role : null;
  if (role !== 'director') {
    msg.textContent = 'Acceso denegado: requiere rol director';
    await firebase.auth().signOut();
    return;
  }

  loginBox.classList.add('hidden');
  userInfo.classList.remove('hidden');
  main.classList.remove('hidden');
  userEmail.textContent = user.email;
  msg.textContent = '';

  subscribeEvents();
});

function subscribeEvents() {
  if (unsubscribe) unsubscribe();
  let query = db.collection('attendance_events').where('verified', '==', true).orderBy('timestamp', 'desc').limit(200);

  unsubscribe = query.onSnapshot(snapshot => {
    eventsTable.innerHTML = '';
    snapshot.forEach(doc => {
      const d = doc.data();
      const tr = document.createElement('tr');
      const ts = d.timestamp ? new Date(d.timestamp.seconds*1000).toLocaleString() : '--';
      tr.innerHTML = `<td>${ts}</td><td>${d.userName||d.userId}</td><td>${d.qrPayload||''}</td><td>${d.deviceId||''}</td><td>${d.verified}</td>`;
      eventsTable.appendChild(tr);
    });
  }, err => { msg.textContent = 'Error escuchando: '+err.message });
}

btnApply.addEventListener('click', () => {
  // simple client-side filter
  const u = filterUser.value.trim().toLowerCase();
  const q = filterQR.value.trim().toLowerCase();
  Array.from(eventsTable.children).forEach(tr => {
    const text = tr.textContent.toLowerCase();
    tr.style.display = (text.includes(u) && text.includes(q)) ? '' : 'none';
  });
});

btnClear.addEventListener('click', () => {
  filterUser.value=''; filterQR.value=''; Array.from(eventsTable.children).forEach(tr=>tr.style.display='');
});

btnExport.addEventListener('click', () => {
  const rows = [['Fecha','Usuario','QR','Device','Verificado']];
  Array.from(eventsTable.children).forEach(tr=>{
    if (tr.style.display==='none') return;
    const cols = Array.from(tr.children).map(td=>td.textContent);
    rows.push(cols);
  });
  const csv = rows.map(r=>r.map(c=>'"'+(c||'')+'"').join(',')).join('\n');
  const blob = new Blob([csv], {type:'text/csv'});
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a'); a.href=url; a.download='attendance.csv'; a.click(); URL.revokeObjectURL(url);
});

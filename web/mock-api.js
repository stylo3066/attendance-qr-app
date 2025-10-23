// Mock API que funciona en GitHub Pages (solo frontend)
class AttendanceAPI {
  constructor() {
    this.baseKey = 'attendance_mock_';
    this.professors = this.loadProfessors();
    this.initializeDemoData();
  }
  
  loadProfessors() {
    return [
      { id: "47045355", nombre: "ALOCILLA FERNANDEZ, FRANCO ANDREE", materia: "Matemática" },
      { id: "40770563", nombre: "CANO AVILA, ROCIO PILAR", materia: "Primaria" },
      { id: "42029091", nombre: "CHAMBI TORRES, JANNETH CARLA", materia: "Primaria" },
      { id: "25691722", nombre: "CASTRO FALCON, DAVID ALBERTO", materia: "Historia" },
      { id: "45649663", nombre: "CORREA ROJAS, JESSAMINE FIORELLA", materia: "Primaria" },
      { id: "10301512", nombre: "DELGADO HUAMAN, NILO", materia: "Primaria" },
      { id: "43228354", nombre: "ESPINOZA GIVERA, YULIANA GLADYS", materia: "Primaria" },
      { id: "10617994", nombre: "LA TORRE DE LA CRUZ, ROSARIO AMPARO", materia: "Primaria" },
      { id: "40839904", nombre: "LEYTON CURO, JANET PAOLA", materia: "Primaria" },
      { id: "41438400", nombre: "LEYTON CURO, KARLA ELIZABETH", materia: "Primaria" }
    ];
  }
  
  // Simular POST /api/attendance
  async postAttendance(data) {
    const { qrCode, deviceId, timestamp, signature } = data;
    
    // Buscar profesor
    const professor = this.professors.find(p => p.id === qrCode);
    if (!professor) {
      throw new Error('Profesor no encontrado');
    }
    
    // Crear registro
    const record = {
      id: Date.now().toString(),
      qrCode,
      deviceId,
      timestamp,
      professorId: professor.id,
      professorFullName: professor.nombre,
      subject: professor.materia,
      serverTimestamp: new Date().toISOString(),
      date: new Date().toISOString().split('T')[0],
      time: new Date().toTimeString().split(' ')[0],
      hour: new Date().getHours(),
      type: Math.random() > 0.7 ? 'SALIDA' : 'ENTRADA',
      status: Math.random() > 0.8 ? 'TARDANZA' : 'PUNTUAL',
      verified: true
    };
    
    // Guardar en localStorage
    const records = this.getAttendance();
    records.push(record);
    localStorage.setItem(this.baseKey + 'records', JSON.stringify(records));
    
    return {
      ok: true,
      id: record.id,
      professor: professor.nombre,
      subject: professor.materia,
      message: `Asistencia registrada: ${professor.nombre} - ${professor.materia}`
    };
  }
  
  // Simular GET /api/attendance
  getAttendance() {
    try {
      const data = localStorage.getItem(this.baseKey + 'records');
      return data ? JSON.parse(data) : [];
    } catch (e) {
      return [];
    }
  }
  
  // Simular DELETE /api/attendance
  clearAttendance() {
    localStorage.removeItem(this.baseKey + 'records');
    return { message: 'Database cleared' };
  }
  
  // Simular GET /api/professors
  getProfessors() {
    return this.professors;
  }
  
  // Simular GET /health
  getHealth() {
    return { status: 'ok', timestamp: new Date().toISOString(), mode: 'github-pages-mock' };
  }
  
  // Inicializar con datos de demostración
  initializeDemoData() {
    const existingData = this.getAttendance();
    if (existingData.length === 0) {
      // Crear algunos registros de demostración
      const today = new Date();
      const demoRecords = [
        {
          id: Date.now().toString(),
          qrCode: '47045355',
          deviceId: 'demo-device-1',
          timestamp: new Date(today.getTime() - 3600000).toISOString(), // 1 hora atrás
          professorId: '47045355',
          professorFullName: 'ALOCILLA FERNANDEZ, FRANCO ANDREE',
          subject: 'Matemática',
          serverTimestamp: new Date(today.getTime() - 3600000).toISOString(),
          date: today.toISOString().split('T')[0],
          time: new Date(today.getTime() - 3600000).toTimeString().split(' ')[0],
          hour: today.getHours() - 1,
          type: 'ENTRADA',
          status: 'PUNTUAL',
          verified: true
        },
        {
          id: (Date.now() + 1).toString(),
          qrCode: '40770563',
          deviceId: 'demo-device-2',
          timestamp: new Date(today.getTime() - 1800000).toISOString(), // 30 min atrás
          professorId: '40770563',
          professorFullName: 'CANO AVILA, ROCIO PILAR',
          subject: 'Primaria',
          serverTimestamp: new Date(today.getTime() - 1800000).toISOString(),
          date: today.toISOString().split('T')[0],
          time: new Date(today.getTime() - 1800000).toTimeString().split(' ')[0],
          hour: today.getHours(),
          type: 'ENTRADA',
          status: 'TARDANZA',
          verified: true
        }
      ];
      
      localStorage.setItem(this.baseKey + 'records', JSON.stringify(demoRecords));
      console.log('📊 Datos de demostración inicializados');
    }
  }
}

// Crear instancia global
window.attendanceAPI = new AttendanceAPI();

// Interceptar fetch para simular servidor
const originalFetch = window.fetch;
window.fetch = function(url, options = {}) {
  const urlStr = typeof url === 'string' ? url : url.toString();
  
  // Si es una llamada a nuestro API mock
  if (urlStr.includes('/api/attendance') || urlStr.includes('/api/professors') || urlStr.includes('/health')) {
    return new Promise((resolve) => {
      setTimeout(() => { // Simular latencia de red
        try {
          let result;
          const api = window.attendanceAPI;
          
          if (urlStr.includes('/health')) {
            result = api.getHealth();
          } else if (urlStr.includes('/api/professors')) {
            result = api.getProfessors();
          } else if (urlStr.includes('/api/attendance')) {
            if (options.method === 'POST') {
              const data = JSON.parse(options.body);
              result = api.postAttendance(data.data || data);
            } else if (options.method === 'DELETE') {
              result = api.clearAttendance();
            } else {
              result = api.getAttendance();
            }
          }
          
          resolve({
            ok: true,
            status: 200,
            json: () => Promise.resolve(result),
            text: () => Promise.resolve(JSON.stringify(result))
          });
        } catch (error) {
          resolve({
            ok: false,
            status: error.message.includes('no encontrado') ? 404 : 500,
            json: () => Promise.resolve({ error: error.message }),
            text: () => Promise.resolve(JSON.stringify({ error: error.message }))
          });
        }
      }, Math.random() * 200 + 100); // 100-300ms latencia
    });
  }
  
  // Para otras URLs, usar fetch normal
  return originalFetch.call(this, url, options);
};

console.log('🚀 Attendance API Mock cargado para GitHub Pages');
console.log('📱 Los QRs ahora funcionarán correctamente en el dashboard');
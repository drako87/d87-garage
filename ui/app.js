let currentVehicles = [];
let selectedVehicle = null;
let currentLocales = {};

window.addEventListener('message', function(event) {
    const data = event.data;
    
    if (data.action === 'open') {
        // Setup Config
        document.documentElement.style.setProperty('--accent', data.config.accentColor || '#00d4ff');
        currentLocales = data.config.locales;
        
        // Update texts
        document.getElementById('garage-name').innerText = data.garage.label;
        document.querySelector('.loc-fuel').innerText = currentLocales.fuel;
        document.querySelector('.loc-engine').innerText = currentLocales.engine;
        document.querySelector('.loc-body').innerText = currentLocales.body;
        document.getElementById('search-input').placeholder = currentLocales.search;

        currentVehicles = data.vehicles || [];
        renderVehicleList(currentVehicles);
        
        document.getElementById('app').style.display = 'flex';
        
        // Reset selection
        selectedVehicle = null;
        document.getElementById('empty-state').style.display = 'flex';
        document.getElementById('details-content').style.display = 'none';
        
    } else if (data.action === 'close') {
        document.getElementById('app').style.display = 'none';
    }
});

document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        closeUI();
    }
});

document.getElementById('search-input').addEventListener('input', function(e) {
    const term = e.target.value.toLowerCase();
    const filtered = currentVehicles.filter(v => 
        v.label.toLowerCase().includes(term) || 
        v.plate.toLowerCase().includes(term)
    );
    renderVehicleList(filtered);
});

function closeUI() {
    fetch(`https://${GetParentResourceName()}/close`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

function getStatusText(state) {
    if (state === 0) return currentLocales.out;
    if (state === 1) return currentLocales.garaged;
    if (state === 2) return currentLocales.impounded;
    return 'UNKNOWN';
}

function renderVehicleList(vehicles) {
    const list = document.getElementById('vehicle-list');
    list.innerHTML = '';
    
    if (vehicles.length === 0) {
        list.innerHTML = `<div style="color:var(--text-sec);text-align:center;padding:20px;">No vehicles found.</div>`;
        return;
    }
    
    vehicles.forEach(v => {
        const card = document.createElement('div');
        card.className = 'vehicle-card';
        card.id = `veh-${v.id}`;
        card.onclick = () => selectVehicle(v);
        
        card.innerHTML = `
            <div class="v-info">
                <div class="v-name">${v.label}</div>
                <div class="v-plate">${v.plate}</div>
            </div>
            <div class="v-status status-${v.state}">
                ${getStatusText(v.state)}
            </div>
        `;
        list.appendChild(card);
    });
}

function selectVehicle(v) {
    selectedVehicle = v;
    
    // Update active class
    document.querySelectorAll('.vehicle-card').forEach(c => c.classList.remove('selected'));
    document.getElementById(`veh-${v.id}`).classList.add('selected');
    
    // Show details
    document.getElementById('empty-state').style.display = 'none';
    document.getElementById('details-content').style.display = 'flex';
    
    // Populate data
    document.getElementById('detail-name').innerText = v.label;
    document.getElementById('detail-plate').innerText = v.plate;
    
    const statusEl = document.getElementById('detail-status');
    statusEl.innerText = getStatusText(v.state);
    statusEl.className = `status-badge status-${v.state}`;
    
    // Progress Bars (assuming values 0-100 or 0-1000)
    const fuelVal = Math.round(v.fuel > 100 ? (v.fuel/1000)*100 : v.fuel);
    const engVal = Math.round(v.engine > 100 ? (v.engine/1000)*100 : v.engine);
    const bodyVal = Math.round(v.body > 100 ? (v.body/1000)*100 : v.body);
    
    updateProgress('fuel', fuelVal);
    updateProgress('engine', engVal);
    updateProgress('body', bodyVal);
    
    // Button and Impound logic
    const btn = document.getElementById('action-btn');
    const impoundInfo = document.getElementById('impound-info');
    
    if (v.state === 1) { // Garaged
        impoundInfo.style.display = 'none';
        btn.innerText = currentLocales.takeOut;
        btn.disabled = false;
        btn.style.background = 'var(--accent)';
    } else if (v.state === 2 || (v.state === 0 && v.depotPrice > 0)) { // Impounded or OUT and in Depot
        impoundInfo.style.display = 'flex';
        document.getElementById('impound-fee').innerText = `$${v.depotPrice}`;
        btn.innerText = currentLocales.payImpound;
        btn.disabled = false;
        btn.style.background = 'var(--status-impound)';
    } else { // OUT (normal garage)
        impoundInfo.style.display = 'none';
        btn.innerText = currentLocales.out;
        btn.disabled = true;
        btn.style.background = 'rgba(255,255,255,0.1)';
    }
}

function updateProgress(type, val) {
    // Colors based on health
    let color = 'var(--status-in)';
    if (val < 40) color = 'var(--status-impound)';
    else if (val < 75) color = 'var(--status-out)';
    
    const fill = document.getElementById(`prog-${type}`);
    fill.style.width = `${Math.max(0, Math.min(100, val))}%`;
    fill.style.background = color;
    
    document.getElementById(`val-${type}`).innerText = `${val}%`;
}

function takeOutSelected() {
    if (!selectedVehicle) return;
    
    fetch(`https://${GetParentResourceName()}/takeOutVehicle`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ id: selectedVehicle.id })
    });
}

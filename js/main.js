let protocolData = {};
let currentNode = 'start';
let gpsCoordinates = { lat: "45.1234", lon: "-122.5678" }; // Mocked offline GPS

// DOM Elements
const appDiv = document.getElementById('app');

// App State
let sessionHistory = [];

async function initApp() {
    try {
        const response = await fetch('data/protocol.json');
        protocolData = await response.json();
        renderHomeScreen();
    } catch (e) {
        console.error("Failed to load protocol data. Ensure you are running via a local server.", e);
        // Fallback for strict file:// execution without a server
        protocolData = getFallbackData(); 
        renderHomeScreen();
    }
}

function renderHomeScreen() {
    appDiv.innerHTML = `
        <div class="screen home-screen">
            <div class="gps-status">
                <div class="gps-dot ready"></div>
                GPS Ready
            </div>
            <h1 class="logo">Survival AId</h1>
            <p class="subtitle">Offline Emergency Assistant</p>
            
            <button class="btn-emergency" onclick="startEmergency()">
                I NEED<br>HELP
            </button>
            
            <button class="btn-secondary" onclick="startPractice()">
                Learn / Practice
            </button>
        </div>
    `;
}

function startEmergency() {
    sessionHistory = [];
    currentNode = 'start';
    renderActiveSession();
    addAiMessage(protocolData.nodes[currentNode].question, protocolData.nodes[currentNode].branches);
}

function startPractice() {
    startEmergency(); // Same flow for now, just a demo
}

function renderActiveSession() {
    appDiv.innerHTML = `
        <div class="screen">
            <div class="header">
                <h2 id="phase-title">Assessment</h2>
                <button class="btn-secondary" style="padding: 8px 16px; width: auto; font-size: 0.9rem;" onclick="showLocation()">My Location</button>
            </div>
            <div class="chat-container" id="chat-box"></div>
            <div class="controls">
                <div class="options-container" id="options-box"></div>
                <button class="btn-mic" onclick="mockVoiceInput()">
                    🎙️ Tap to Speak
                </button>
            </div>
        </div>
    `;
}

function addAiMessage(text, branches) {
    const chatBox = document.getElementById('chat-box');
    const msgDiv = document.createElement('div');
    msgDiv.className = 'message msg-ai';
    msgDiv.innerText = text;
    chatBox.appendChild(msgDiv);
    chatBox.scrollTop = chatBox.scrollHeight;

    const optionsBox = document.getElementById('options-box');
    optionsBox.innerHTML = '';
    
    if (branches) {
        branches.forEach(branch => {
            const btn = document.createElement('button');
            btn.className = 'btn-secondary';
            btn.innerText = branch.label;
            btn.onclick = () => handleUserChoice(branch);
            optionsBox.appendChild(btn);
        });
    }
}

function addUserMessage(text) {
    const chatBox = document.getElementById('chat-box');
    const msgDiv = document.createElement('div');
    msgDiv.className = 'message msg-user';
    msgDiv.innerText = text;
    chatBox.appendChild(msgDiv);
    chatBox.scrollTop = chatBox.scrollHeight;
    
    document.getElementById('options-box').innerHTML = '';
}

function handleUserChoice(branch) {
    addUserMessage(branch.label);
    
    setTimeout(() => {
        currentNode = branch.target;
        if (currentNode === 'rescue_call') {
            renderRescueScript();
        } else if (currentNode === 'end') {
            renderHomeScreen();
        } else {
            const node = protocolData.nodes[currentNode];
            document.getElementById('phase-title').innerText = node.source ? `Source: ${node.source}` : 'Assessment';
            addAiMessage(node.question, node.branches);
        }
    }, 600);
}

function mockVoiceInput() {
    alert("Voice input simulation: Assume the user says 'Yes'.");
    const node = protocolData.nodes[currentNode];
    if(node.branches && node.branches.length > 0) {
        handleUserChoice(node.branches[0]);
    }
}

function renderRescueScript() {
    appDiv.innerHTML = `
        <div class="screen script-screen">
            <h1 style="color: white; margin-bottom: 8px;">Rescue Call Script</h1>
            <p style="color: rgba(255,255,255,0.8);">Read this exactly to the operator.</p>
            
            <div class="script-box">
                <div class="coord-display">
                    LAT: ${gpsCoordinates.lat}<br>
                    LON: ${gpsCoordinates.lon}
                </div>
                <p style="color: white; font-weight: 600;">
                    "I have an emergency. I need rescue. My location coordinates are Latitude 45 point 1 2 3 4, Longitude negative 122 point 5 6 7 8."
                </p>
            </div>
            
            <button class="btn-secondary" style="background: white; color: var(--accent-red); border: none;" onclick="continueSession()">
                I've spoken to rescuers - Continue
            </button>
        </div>
    `;
}

function continueSession() {
    const node = protocolData.nodes[currentNode];
    renderActiveSession();
    if(node.branches && node.branches.length > 0) {
        // Move to next step automatically
        currentNode = node.branches[0].target;
        const nextNode = protocolData.nodes[currentNode];
        addAiMessage(nextNode.question, nextNode.branches);
    }
}

function showLocation() {
    alert(`Current GPS Location (Offline GNSS):\nLAT: ${gpsCoordinates.lat}\nLON: ${gpsCoordinates.lon}\nAltitude: 1200m`);
}

function getFallbackData() {
    // Exact same as protocol.json, used if file:// origin restricts fetch
    return {
        "nodes": {
            "start": {
                "id": "start",
                "question": "Are you or anyone else injured?",
                "source": "Red Cross Wilderness First Aid",
                "branches": [
                    {"label": "Yes", "target": "injury_assessment"},
                    {"label": "No, just lost", "target": "lost_protocol"}
                ]
            },
            "injury_assessment": {
                "id": "injury_assessment",
                "question": "Is there severe, life-threatening bleeding?",
                "branches": [
                    {"label": "Yes", "target": "rescue_call"},
                    {"label": "No", "target": "lost_protocol"}
                ]
            },
            "lost_protocol": {
                "id": "lost_protocol",
                "question": "Do you have mobile signal to make a call?",
                "branches": [
                    {"label": "Yes", "target": "rescue_call"},
                    {"label": "No", "target": "end"}
                ]
            },
            "rescue_call": {
                "id": "rescue_call",
                "branches": [{"label": "Continue", "target": "end"}]
            },
            "end": {
                "id": "end",
                "question": "Session ended. Stay safe.",
                "branches": [{"label": "Home", "target": "start"}]
            }
        }
    };
}

// Start
initApp();

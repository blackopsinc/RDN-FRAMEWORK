/**
 * RDN Framework Enhanced JavaScript v7.0
 * Modern Command & Control Interface
 */

class RDNFramework {
    constructor() {
        // Use the correct API endpoint
        this.apiBase = '/server/api';
        this.currentSection = 'dashboard';
        this.hosts = [];
        this.commands = [];
        this.charts = {};
        this.consoleHistory = [];
        this.consoleHistoryIndex = -1;
        this.selectedHost = null;
        this.refreshInterval = null;
        this.websocket = null;
        
        this.init();
    }

    init() {
        this.setupEventListeners();
        this.initializeCharts();
        this.loadHosts(); // Load hosts first
        this.loadDashboardData();
        this.startAutoRefresh();
        this.connectWebSocket();
    }

    setupEventListeners() {
        // Navigation
        document.querySelectorAll('[data-section]').forEach(link => {
            link.addEventListener('click', (e) => {
                e.preventDefault();
                this.showSection(link.dataset.section);
            });
        });

        // Console input
        const consoleInput = document.getElementById('console-input');
        if (consoleInput) {
            consoleInput.addEventListener('keydown', (e) => {
                this.handleConsoleKeydown(e);
            });
        }

        // Host selection
        const hostSelect = document.getElementById('console-host-select');
        if (hostSelect) {
            hostSelect.addEventListener('change', (e) => {
                this.selectedHost = e.target.value;
                const selectedHost = this.hosts.find(h => h.id.toString() === e.target.value) || 
                                   (e.target.value === 'localhost-fallback' ? { name: 'localhost', fqdn: '127.0.0.1' } : null);
                if (selectedHost) {
                    this.updateConsolePrompt(selectedHost);
                }
            });
        }

        // Window resize
        window.addEventListener('resize', () => {
            this.resizeCharts();
        });
    }

    showSection(sectionName) {
        // Hide all sections
        document.querySelectorAll('.content-section').forEach(section => {
            section.classList.add('d-none');
        });

        // Show selected section
        const targetSection = document.getElementById(`${sectionName}-section`);
        if (targetSection) {
            targetSection.classList.remove('d-none');
            targetSection.classList.add('fade-in');
        }

        // Update navigation
        document.querySelectorAll('[data-section]').forEach(link => {
            link.classList.remove('active');
        });
        document.querySelector(`[data-section="${sectionName}"]`).classList.add('active');

        this.currentSection = sectionName;

        // Load section-specific data
        switch (sectionName) {
            case 'dashboard':
                this.loadDashboardData();
                break;
            case 'hosts':
                this.loadHosts();
                break;
            case 'console':
                this.loadConsoleHosts();
                this.focusConsoleInput();
                break;
            case 'files':
                this.loadFiles();
                break;
            case 'audit':
                this.loadAuditLogs();
                break;
            case 'settings':
                this.loadSettings();
                break;
        }
    }

    async loadDashboardData() {
        try {
            this.showLoading();
            
            // Load dashboard statistics
            const stats = await this.apiCall('/dashboard/stats');
            this.updateDashboardStats(stats);
            
            // Load recent activity
            const activity = await this.apiCall('/dashboard/activity');
            this.updateRecentActivity(activity);
            
            // Update charts
            this.updateCharts();
            
        } catch (error) {
            console.error('Error loading dashboard data:', error);
            this.showNotification('Error loading dashboard data', 'error');
        } finally {
            this.hideLoading();
        }
    }

    updateDashboardStats(stats) {
        document.getElementById('active-hosts').textContent = stats.activeHosts || 0;
        document.getElementById('commands-today').textContent = stats.commandsToday || 0;
        document.getElementById('pending-tasks').textContent = stats.pendingTasks || 0;
        document.getElementById('failed-commands').textContent = stats.failedCommands || 0;
    }

    updateRecentActivity(activity) {
        const tbody = document.getElementById('recent-activity');
        if (!tbody) return;

        if (!activity || activity.length === 0) {
            tbody.innerHTML = '<tr><td colspan="5" class="text-center text-muted">No recent activity</td></tr>';
            return;
        }

        tbody.innerHTML = activity.map(item => `
            <tr>
                <td>${this.formatDateTime(item.timestamp)}</td>
                <td>${this.escapeHtml(item.host)}</td>
                <td><code>${this.escapeHtml(item.command)}</code></td>
                <td><span class="status-badge status-${item.status}">${item.status}</span></td>
                <td>${this.escapeHtml(item.user)}</td>
            </tr>
        `).join('');
    }

    async loadHosts() {
        try {
            this.showLoading();
            console.log('Loading hosts from:', this.apiBase + '/hosts');
            const hosts = await this.apiCall('/hosts');
            console.log('Hosts loaded:', hosts);
            this.hosts = hosts;
            this.updateHostsTable(hosts);
        } catch (error) {
            console.error('Error loading hosts:', error);
            console.error('API Base:', this.apiBase);
            console.error('Full URL:', this.apiBase + '/hosts');
            this.showNotification('Error loading hosts: ' + error.message, 'error');
        } finally {
            this.hideLoading();
        }
    }

    updateHostsTable(hosts) {
        const tbody = document.getElementById('hosts-table');
        if (!tbody) return;

        if (!hosts || hosts.length === 0) {
            tbody.innerHTML = '<tr><td colspan="7" class="text-center text-muted">No hosts configured</td></tr>';
            return;
        }

        tbody.innerHTML = hosts.map(host => `
            <tr>
                <td>${this.escapeHtml(host.name)}</td>
                <td><span class="badge bg-secondary">${host.type}</span></td>
                <td>
                    <i class="fas fa-${this.getOSIcon(host.os)} me-1"></i>
                    ${host.os}
                </td>
                <td>${this.escapeHtml(host.fqdn)}</td>
                <td><span class="status-badge status-${host.status}">${host.status}</span></td>
                <td>${host.last_seen ? this.formatDateTime(host.last_seen) : 'Never'}</td>
                <td>
                    <div class="btn-group btn-group-sm">
                        <button class="btn btn-outline-primary" onclick="testHost(${host.id})" title="Test Connection">
                            <i class="fas fa-plug"></i>
                        </button>
                        <button class="btn btn-outline-info" onclick="editHost(${host.id})" title="Edit">
                            <i class="fas fa-edit"></i>
                        </button>
                        <button class="btn btn-outline-danger" onclick="deleteHost(${host.id})" title="Delete">
                            <i class="fas fa-trash"></i>
                        </button>
                    </div>
                </td>
            </tr>
        `).join('');
    }

    loadConsoleHosts() {
        const select = document.getElementById('console-host-select');
        if (!select) return;

        // Keep the existing selection if any
        const currentSelection = select.value;
        
        select.innerHTML = '<option value="">Select a host...</option>';
        
        // Find localhost in database hosts first
        let localhostHost = this.hosts.find(host => 
            host.name.toLowerCase() === 'localhost' || 
            host.fqdn.toLowerCase() === 'localhost' ||
            host.fqdn === '127.0.0.1'
        );
        
        let defaultSelected = false;
        
        // Add all hosts including localhost from database
        this.hosts.filter(host => host.status === 'active' || host.status === 'online').forEach(host => {
            const option = document.createElement('option');
            option.value = host.id;
            
            // Special formatting for localhost
            if (host.name.toLowerCase() === 'localhost' || host.fqdn.toLowerCase() === 'localhost' || host.fqdn === '127.0.0.1') {
                option.textContent = `localhost (${host.fqdn})`;
                // Auto-select localhost if no current selection
                if (!currentSelection && !defaultSelected) {
                    option.selected = true;
                    this.selectedHost = host.id;
                    defaultSelected = true;
                    this.updateConsolePrompt(host);
                }
            } else {
                option.textContent = `${host.name} (${host.fqdn})`;
            }
            
            if (currentSelection === host.id.toString()) {
                option.selected = true;
                this.selectedHost = host.id;
                this.updateConsolePrompt(host);
            }
            
            select.appendChild(option);
        });
        
        // If no localhost found in database, add a fallback localhost option
        if (!localhostHost) {
            const localhostOption = document.createElement('option');
            localhostOption.value = 'localhost-fallback';
            localhostOption.textContent = 'localhost (127.0.0.1)';
            if (!currentSelection && !defaultSelected) {
                localhostOption.selected = true;
                this.selectedHost = 'localhost-fallback';
                this.updateConsolePrompt({ name: 'localhost', fqdn: '127.0.0.1' });
            }
            select.appendChild(localhostOption);
        }
    }

    updateConsolePrompt(host) {
        const promptElement = document.getElementById('console-prompt');
        if (promptElement && host) {
            // Keep the simple prompt style consistent with the cleaned up design
            promptElement.textContent = '$';
        }
    }

    focusConsoleInput() {
        // Focus the console input with a slight delay to ensure the section is visible
        setTimeout(() => {
            const consoleInput = document.getElementById('console-input');
            if (consoleInput) {
                consoleInput.focus();
                // Add welcome message if console is empty
                const consoleOutput = document.getElementById('console-output');
                if (consoleOutput && consoleOutput.innerHTML.trim() === '') {
                    this.addConsoleOutput('Welcome to RDN Framework Console', 'console-success');
                    this.addConsoleOutput('Type commands and use ↑/↓ arrows to navigate history', 'console-output-text');
                    this.addConsoleOutput('', ''); // Empty line
                }
            }
        }, 100);
    }

    handleConsoleKeydown(e) {
        const input = e.target;
        
        switch (e.key) {
            case 'Enter':
                e.preventDefault();
                this.executeCommand();
                break;
            case 'ArrowUp':
                e.preventDefault();
                this.navigateHistory(-1);
                break;
            case 'ArrowDown':
                e.preventDefault();
                this.navigateHistory(1);
                break;
            case 'Tab':
                e.preventDefault();
                this.autoComplete(input);
                break;
        }
    }

    navigateHistory(direction) {
        if (this.consoleHistory.length === 0) return;

        this.consoleHistoryIndex += direction;
        
        if (this.consoleHistoryIndex < 0) {
            this.consoleHistoryIndex = -1;
            document.getElementById('console-input').value = '';
        } else if (this.consoleHistoryIndex >= this.consoleHistory.length) {
            this.consoleHistoryIndex = this.consoleHistory.length - 1;
        }

        if (this.consoleHistoryIndex >= 0) {
            document.getElementById('console-input').value = this.consoleHistory[this.consoleHistoryIndex];
        }
    }

    async executeCommand() {
        const input = document.getElementById('console-input');
        const command = input.value.trim();
        
        if (!command) return;
        if (!this.selectedHost) {
            this.showNotification('Please select a host first', 'warning');
            return;
        }

        // Add to history
        if (this.consoleHistory[this.consoleHistory.length - 1] !== command) {
            this.consoleHistory.push(command);
            if (this.consoleHistory.length > 100) {
                this.consoleHistory.shift();
            }
        }
        this.consoleHistoryIndex = -1;

        // Clear input
        input.value = '';

        // Get current prompt for display
        const promptElement = document.getElementById('console-prompt');
        const promptText = promptElement ? promptElement.textContent.replace(/\n/g, ' ') : '$ ';

        // Add command to output with simple prompt
        this.addConsoleOutput(`${promptText} ${command}`, 'console-command');

        try {
            // Use GET request since POST data parsing has issues
            const response = await this.apiCall(`/console/execute?host_id=${this.selectedHost}&command=${encodeURIComponent(command)}`);

            if (response.success) {
                this.addConsoleOutput(response.output, 'console-output-text');
            } else {
                this.addConsoleOutput(response.error || 'Command failed', 'console-error');
            }
        } catch (error) {
            this.addConsoleOutput(`Error: ${error.message}`, 'console-error');
        }
    }

    addConsoleOutput(text, className = '') {
        const output = document.getElementById('console-output');
        if (!output) return;

        const line = document.createElement('div');
        line.className = `console-line ${className}`;
        line.textContent = text;
        
        output.appendChild(line);
        output.scrollTop = output.scrollHeight;
    }

    clearConsole() {
        const output = document.getElementById('console-output');
        if (output) {
            output.innerHTML = '';
        }
    }

    initializeCharts() {
        // Activity Chart
        const activityCtx = document.getElementById('activityChart');
        if (activityCtx) {
            this.charts.activity = new Chart(activityCtx, {
                type: 'line',
                data: {
                    labels: [],
                    datasets: [{
                        label: 'Commands',
                        data: [],
                        borderColor: '#0d6efd',
                        backgroundColor: 'rgba(13, 110, 253, 0.1)',
                        tension: 0.4
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: {
                            labels: {
                                color: '#ffffff'
                            }
                        }
                    },
                    scales: {
                        x: {
                            ticks: {
                                color: '#ffffff'
                            },
                            grid: {
                                color: 'rgba(255, 255, 255, 0.1)'
                            }
                        },
                        y: {
                            ticks: {
                                color: '#ffffff'
                            },
                            grid: {
                                color: 'rgba(255, 255, 255, 0.1)'
                            }
                        }
                    }
                }
            });
        }

        // Host Status Chart
        const hostStatusCtx = document.getElementById('hostStatusChart');
        if (hostStatusCtx) {
            this.charts.hostStatus = new Chart(hostStatusCtx, {
                type: 'doughnut',
                data: {
                    labels: ['Active', 'Inactive', 'Error', 'Maintenance'],
                    datasets: [{
                        data: [0, 0, 0, 0],
                        backgroundColor: [
                            '#198754',
                            '#6c757d',
                            '#dc3545',
                            '#ffc107'
                        ]
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: {
                            labels: {
                                color: '#ffffff'
                            }
                        }
                    }
                }
            });
        }
    }

    updateCharts() {
        // Update activity chart with mock data for now
        if (this.charts.activity) {
            const hours = [];
            const data = [];
            
            for (let i = 23; i >= 0; i--) {
                const hour = new Date();
                hour.setHours(hour.getHours() - i);
                hours.push(hour.toLocaleTimeString('en-US', { hour: '2-digit' }));
                data.push(Math.floor(Math.random() * 50));
            }
            
            this.charts.activity.data.labels = hours;
            this.charts.activity.data.datasets[0].data = data;
            this.charts.activity.update();
        }

        // Update host status chart
        if (this.charts.hostStatus && this.hosts.length > 0) {
            const statusCounts = {
                active: 0,
                inactive: 0,
                error: 0,
                maintenance: 0
            };

            this.hosts.forEach(host => {
                statusCounts[host.status] = (statusCounts[host.status] || 0) + 1;
            });

            this.charts.hostStatus.data.datasets[0].data = [
                statusCounts.active,
                statusCounts.inactive,
                statusCounts.error,
                statusCounts.maintenance
            ];
            this.charts.hostStatus.update();
        }
    }

    resizeCharts() {
        Object.values(this.charts).forEach(chart => {
            if (chart) chart.resize();
        });
    }

    async addHost() {
        const form = document.getElementById('addHostForm');
        const formData = new FormData(form);
        
        const hostData = {
            name: formData.get('hostName'),
            type: formData.get('hostType'),
            os: formData.get('hostOS'),
            fqdn: formData.get('hostFQDN'),
            connection_string: formData.get('hostConnection')
        };

        try {
            const response = await this.apiCall('/hosts', {
                method: 'POST',
                body: JSON.stringify(hostData)
            });

            if (response.success) {
                this.showNotification('Host added successfully', 'success');
                bootstrap.Modal.getInstance(document.getElementById('addHostModal')).hide();
                form.reset();
                this.loadHosts();
            } else {
                this.showNotification(response.error || 'Failed to add host', 'error');
            }
        } catch (error) {
            this.showNotification('Error adding host', 'error');
        }
    }

    async testHost(hostId) {
        try {
            this.showLoading();
            const response = await this.apiCall(`/hosts/${hostId}/test`, {
                method: 'POST'
            });

            if (response.success) {
                this.showNotification('Host connection successful', 'success');
            } else {
                this.showNotification('Host connection failed', 'error');
            }
        } catch (error) {
            this.showNotification('Error testing host connection', 'error');
        } finally {
            this.hideLoading();
        }
    }

    async deleteHost(hostId) {
        if (!confirm('Are you sure you want to delete this host?')) return;

        try {
            const response = await this.apiCall(`/hosts/${hostId}`, {
                method: 'DELETE'
            });

            if (response.success) {
                this.showNotification('Host deleted successfully', 'success');
                this.loadHosts();
            } else {
                this.showNotification('Failed to delete host', 'error');
            }
        } catch (error) {
            this.showNotification('Error deleting host', 'error');
        }
    }

    async editHost(hostId) {
        try {
            // Get host data
            const host = await this.apiCall(`/hosts/${hostId}`);
            
            if (host.error) {
                this.showNotification('Error loading host data: ' + host.error, 'error');
                return;
            }
            
            // Populate edit form
            document.getElementById('editHostId').value = host.id;
            document.getElementById('editHostName').value = host.name;
            document.getElementById('editHostType').value = host.type;
            document.getElementById('editHostOS').value = host.os;
            document.getElementById('editHostFQDN').value = host.fqdn;
            document.getElementById('editHostConnection').value = host.connection_string;
            
            // Show modal
            const modal = new bootstrap.Modal(document.getElementById('editHostModal'));
            modal.show();
        } catch (error) {
            this.showNotification('Error loading host data', 'error');
        }
    }

    async updateHost() {
        const form = document.getElementById('editHostForm');
        const formData = new FormData(form);
        const hostId = document.getElementById('editHostId').value;
        
        const hostData = {
            name: formData.get('hostName'),
            type: formData.get('hostType'),
            os: formData.get('hostOS'),
            fqdn: formData.get('hostFQDN'),
            connection_string: formData.get('hostConnection')
        };

        try {
            const response = await this.apiCall(`/hosts/${hostId}`, {
                method: 'PUT',
                body: JSON.stringify(hostData)
            });

            if (response.success) {
                this.showNotification('Host updated successfully', 'success');
                bootstrap.Modal.getInstance(document.getElementById('editHostModal')).hide();
                this.loadHosts();
            } else {
                this.showNotification(response.error || 'Failed to update host', 'error');
            }
        } catch (error) {
            this.showNotification('Error updating host', 'error');
        }
    }

    async apiCall(endpoint, options = {}) {
        const defaultOptions = {
            method: 'GET',
            headers: {
                'Content-Type': 'application/json',
                'X-Requested-With': 'XMLHttpRequest'
            }
        };

        const response = await fetch(this.apiBase + endpoint, {
            ...defaultOptions,
            ...options
        });

        if (!response.ok) {
            throw new Error(`HTTP ${response.status}: ${response.statusText}`);
        }

        return await response.json();
    }

    connectWebSocket() {
        const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
        const wsUrl = `${protocol}//${window.location.host}/ws`;
        
        try {
            this.websocket = new WebSocket(wsUrl);
            
            this.websocket.onopen = () => {
                console.log('WebSocket connected');
            };
            
            this.websocket.onmessage = (event) => {
                const data = JSON.parse(event.data);
                this.handleWebSocketMessage(data);
            };
            
            this.websocket.onclose = () => {
                console.log('WebSocket disconnected, attempting to reconnect...');
                setTimeout(() => this.connectWebSocket(), 5000);
            };
            
            this.websocket.onerror = (error) => {
                console.error('WebSocket error:', error);
            };
        } catch (error) {
            console.error('Failed to connect WebSocket:', error);
        }
    }

    handleWebSocketMessage(data) {
        switch (data.type) {
            case 'host_status_update':
                this.updateHostStatus(data.host_id, data.status);
                break;
            case 'command_completed':
                this.handleCommandCompleted(data);
                break;
            case 'notification':
                this.showNotification(data.message, data.level);
                break;
        }
    }

    updateHostStatus(hostId, status) {
        const host = this.hosts.find(h => h.id === hostId);
        if (host) {
            host.status = status;
            if (this.currentSection === 'hosts') {
                this.updateHostsTable(this.hosts);
            }
        }
    }

    startAutoRefresh() {
        this.refreshInterval = setInterval(() => {
            if (this.currentSection === 'dashboard') {
                this.loadDashboardData();
            }
        }, 30000); // Refresh every 30 seconds
    }

    stopAutoRefresh() {
        if (this.refreshInterval) {
            clearInterval(this.refreshInterval);
            this.refreshInterval = null;
        }
    }

    showLoading() {
        document.getElementById('loadingOverlay').classList.add('show');
    }

    hideLoading() {
        document.getElementById('loadingOverlay').classList.remove('show');
    }

    showNotification(message, type = 'info') {
        // Create notification element
        const notification = document.createElement('div');
        notification.className = `alert alert-${type === 'error' ? 'danger' : type} alert-dismissible fade show position-fixed`;
        notification.style.cssText = 'top: 20px; right: 20px; z-index: 10000; min-width: 300px;';
        notification.innerHTML = `
            ${message}
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        `;

        document.body.appendChild(notification);

        // Auto-remove after 5 seconds
        setTimeout(() => {
            if (notification.parentNode) {
                notification.remove();
            }
        }, 5000);
    }

    formatDateTime(timestamp) {
        return new Date(timestamp).toLocaleString();
    }

    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }

    getOSIcon(os) {
        const icons = {
            linux: 'linux',
            windows: 'windows',
            macos: 'apple',
            freebsd: 'freebsd',
            other: 'server'
        };
        return icons[os] || 'server';
    }

    formatFileSize(bytes) {
        if (bytes === 0) return '0 B';
        const k = 1024;
        const sizes = ['B', 'KB', 'MB', 'GB'];
        const i = Math.floor(Math.log(bytes) / Math.log(k));
        return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
    }

    getSeverityColor(severity) {
        const colors = {
            low: 'success',
            medium: 'warning',
            high: 'danger',
            critical: 'danger'
        };
        return colors[severity] || 'secondary';
    }

    logout() {
        if (confirm('Are you sure you want to logout?')) {
            window.location.href = '/server/cgi-bin/rdn_server/rdn_logout';
        }
    }
}

// Global functions for HTML onclick handlers
function initializeApp() {
    window.rdnApp = new RDNFramework();
}

function executeCommand() {
    window.rdnApp.executeCommand();
}

function clearConsole() {
    window.rdnApp.clearConsole();
}

function addHost() {
    window.rdnApp.addHost();
}

function testHost(hostId) {
    window.rdnApp.testHost(hostId);
}

function editHost(hostId) {
    window.rdnApp.editHost(hostId);
}

function deleteHost(hostId) {
    window.rdnApp.deleteHost(hostId);
}

function logout() {
    window.rdnApp.logout();
}

function handleConsoleInput(event) {
    if (event.key === 'Enter') {
        executeCommand();
    }
}

// Export for module systems
if (typeof module !== 'undefined' && module.exports) {
    module.exports = RDNFramework;
}

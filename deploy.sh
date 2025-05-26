#!/bin/bash

# RDN Framework v7.0 Deployment Script
# Enhanced Command & Control Platform

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
RDN_VERSION="7.0.0"
COMPOSE_FILE="docker-compose.yml"
CONFIG_FILE="rdn_server/cgi-bin/rdn_server/config.conf"

# Functions
print_banner() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    RDN Framework v${RDN_VERSION}                    ║"
    echo "║              Enhanced Command & Control Platform             ║"
    echo "║                                                              ║"
    echo "║  Modern • Secure • Scalable • Docker-Ready                  ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_requirements() {
    log_info "Checking system requirements..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        log_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    
    # Check Docker daemon
    if ! docker info &> /dev/null; then
        log_error "Docker daemon is not running. Please start Docker first."
        exit 1
    fi
    
    log_success "All requirements met"
}

create_directories() {
    log_info "Creating required directories..."
    
    mkdir -p logs
    mkdir -p nginx/ssl
    mkdir -p rdn_data/db/backup
    mkdir -p rdn_data/redis
    
    log_success "Directories created"
}

generate_ssl_certificates() {
    if [ ! -f "nginx/ssl/rdn.crt" ] || [ ! -f "nginx/ssl/rdn.key" ]; then
        log_info "Generating SSL certificates..."
        
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout nginx/ssl/rdn.key \
            -out nginx/ssl/rdn.crt \
            -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost" \
            2>/dev/null
        
        log_success "SSL certificates generated"
    else
        log_info "SSL certificates already exist"
    fi
}

configure_environment() {
    log_info "Configuring environment..."
    
    # Detect environment
    if [ -n "$CODESPACE_NAME" ]; then
        ENVIRONMENT="codespace"
        HOSTNAME="${CODESPACE_NAME}-8080.app.github.dev"
        PROTOCOL="https"
        log_info "Detected GitHub Codespace environment"
    elif [ "$1" = "production" ]; then
        ENVIRONMENT="production"
        read -p "Enter your domain name: " HOSTNAME
        PROTOCOL="https"
        log_info "Configuring for production environment"
    else
        ENVIRONMENT="local"
        HOSTNAME="localhost"
        PROTOCOL="http"
        log_info "Configuring for local development"
    fi
    
    # Update configuration
    if [ "$ENVIRONMENT" != "local" ]; then
        log_info "Updating configuration for $ENVIRONMENT..."
        
        # Backup original config
        cp "$CONFIG_FILE" "${CONFIG_FILE}.backup"
        
        # Update hostname configuration
        sed -i.tmp "s/#\$rdn_hostname = \"<codespace>-8080.app.github.dev\";/\$rdn_hostname = \"$HOSTNAME\";/" "$CONFIG_FILE"
        sed -i.tmp "s/#\$rdn_server = \"https:\/\/\" \. \$rdn_hostname;/\$rdn_server = \"$PROTOCOL:\/\/\" \. \$rdn_hostname;/" "$CONFIG_FILE"
        sed -i.tmp "s/\$rdn_hostname = \"localhost\";/#\$rdn_hostname = \"localhost\";/" "$CONFIG_FILE"
        sed -i.tmp "s/\$rdn_server = \"http:\/\/\" \. \$rdn_hostname;/#\$rdn_server = \"http:\/\/\" \. \$rdn_hostname;/" "$CONFIG_FILE"
        
        # Clean up temp files
        rm -f "${CONFIG_FILE}.tmp"
        
        log_success "Configuration updated for $HOSTNAME"
    fi
}

start_services() {
    log_info "Starting RDN Framework services..."
    
    # Pull latest images
    docker-compose pull
    
    # Start services
    docker-compose up -d
    
    # Wait for services to be ready
    log_info "Waiting for services to start..."
    sleep 10
    
    # Check service health
    if docker-compose ps | grep -q "Up"; then
        log_success "Services started successfully"
    else
        log_error "Some services failed to start"
        docker-compose logs
        exit 1
    fi
}

show_access_info() {
    log_success "RDN Framework v${RDN_VERSION} deployed successfully!"
    echo
    echo -e "${GREEN}Access Information:${NC}"
    
    if [ "$ENVIRONMENT" = "codespace" ]; then
        echo -e "  URL: ${BLUE}https://${HOSTNAME}${NC}"
    elif [ "$ENVIRONMENT" = "production" ]; then
        echo -e "  URL: ${BLUE}https://${HOSTNAME}${NC}"
    else
        echo -e "  URL: ${BLUE}http://localhost:8080${NC}"
    fi
    
    echo -e "  Username: ${YELLOW}admin${NC}"
    echo -e "  Password: ${YELLOW}changeme123!${NC}"
    echo
    echo -e "${RED}⚠️  IMPORTANT: Change the default password immediately after login!${NC}"
    echo
    echo -e "${GREEN}Management Commands:${NC}"
    echo -e "  View logs:        ${BLUE}docker-compose logs -f${NC}"
    echo -e "  Stop services:    ${BLUE}docker-compose down${NC}"
    echo -e "  Restart services: ${BLUE}docker-compose restart${NC}"
    echo -e "  Service status:   ${BLUE}docker-compose ps${NC}"
    echo
}

show_help() {
    echo "RDN Framework v${RDN_VERSION} Deployment Script"
    echo
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo
    echo "Commands:"
    echo "  deploy [local|production]  Deploy the framework (default: local)"
    echo "  start                      Start services"
    echo "  stop                       Stop services"
    echo "  restart                    Restart services"
    echo "  status                     Show service status"
    echo "  logs                       Show service logs"
    echo "  backup                     Create system backup"
    echo "  update                     Update to latest version"
    echo "  clean                      Clean up containers and volumes"
    echo "  help                       Show this help message"
    echo
    echo "Examples:"
    echo "  $0 deploy local            Deploy for local development"
    echo "  $0 deploy production       Deploy for production"
    echo "  $0 status                  Check service status"
    echo "  $0 logs                    View real-time logs"
}

backup_system() {
    log_info "Creating system backup..."
    
    BACKUP_NAME="rdn-backup-$(date +%Y%m%d-%H%M%S)"
    
    # Create database backup
    docker exec rdn-data mysqldump -u root -pchangeme rdn > "${BACKUP_NAME}.sql" 2>/dev/null || true
    
    # Create full system backup
    tar -czf "${BACKUP_NAME}.tar.gz" \
        --exclude='logs/*' \
        --exclude='rdn_data/data/*' \
        --exclude='*.log' \
        . 2>/dev/null
    
    log_success "Backup created: ${BACKUP_NAME}.tar.gz"
}

update_system() {
    log_info "Updating RDN Framework..."
    
    # Pull latest images
    docker-compose pull
    
    # Restart services
    docker-compose down
    docker-compose up -d
    
    log_success "Update completed"
}

clean_system() {
    log_warning "This will remove all containers, volumes, and data!"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Cleaning up system..."
        
        docker-compose down -v --remove-orphans
        docker system prune -f
        
        log_success "System cleaned"
    else
        log_info "Cleanup cancelled"
    fi
}

# Main script
main() {
    print_banner
    
    case "${1:-deploy}" in
        "deploy")
            check_requirements
            create_directories
            generate_ssl_certificates
            configure_environment "$2"
            start_services
            show_access_info
            ;;
        "start")
            docker-compose up -d
            log_success "Services started"
            ;;
        "stop")
            docker-compose down
            log_success "Services stopped"
            ;;
        "restart")
            docker-compose restart
            log_success "Services restarted"
            ;;
        "status")
            docker-compose ps
            ;;
        "logs")
            docker-compose logs -f
            ;;
        "backup")
            backup_system
            ;;
        "update")
            update_system
            ;;
        "clean")
            clean_system
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            log_error "Unknown command: $1"
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"

#!/bin/bash

# 🌐 Script pour récupérer les URLs des services déployés
# Usage: ./scripts/get-urls.sh

set -e
export AWS_PAGER=""

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   📡 URLs des Services Déployés${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo ""

# Update kubeconfig
echo -e "${YELLOW}🔄 Mise à jour de la configuration Kubernetes...${NC}"
aws eks update-kubeconfig --name student-team4-iac-dev-cluster --region us-east-1 > /dev/null 2>&1 || {
    echo -e "${YELLOW}⚠️  Impossible de mettre à jour kubeconfig${NC}"
}

echo ""
echo -e "${GREEN}📊 Récupération via AWS Load Balancers:${NC}"
echo ""

# Get LoadBalancers
echo "Recherche des Load Balancers..."
aws elbv2 describe-load-balancers --region us-east-1 --query 'LoadBalancers[?contains(LoadBalancerName, `k8s`)].{Name:LoadBalancerName,DNS:DNSName,State:State.Code}' --output json 2>/dev/null | jq -r '.[] | "  • \(.Name)\n    URL: http://\(.DNS)\n    État: \(.State)\n"' || {
    echo -e "${YELLOW}  ⚠️  Aucun Load Balancer trouvé${NC}"
}

echo ""
echo -e "${GREEN}💡 Endpoints probables:${NC}"
echo ""

# Try to get service info
BACKEND_LB=$(aws elbv2 describe-load-balancers --region us-east-1 --query 'LoadBalancers[?contains(LoadBalancerName, `taskman`)].DNSName | [0]' --output text 2>/dev/null)

if [ ! -z "$BACKEND_LB" ] && [ "$BACKEND_LB" != "None" ]; then
    echo -e "  🔧 ${BLUE}Backend API:${NC} http://$BACKEND_LB:8000"
    echo -e "  📖 ${BLUE}API Docs (Swagger):${NC} http://$BACKEND_LB:8000/docs"
    echo -e "  ❤️  ${BLUE}Health Check:${NC} http://$BACKEND_LB:8000/health"
    echo -e "  📊 ${BLUE}Metrics:${NC} http://$BACKEND_LB:8000/metrics"
else
    echo -e "  ${YELLOW}⚠️  Backend LoadBalancer introuvable${NC}"
    echo -e "  ${BLUE}💡 Solution: Utilise kubectl port-forward (voir ci-dessous)${NC}"
fi

echo ""
echo -e "${GREEN}🔧 Alternative - Port Forward (accès local):${NC}"
echo ""
echo "  # Terminal 1 - Backend:"
echo "  kubectl port-forward svc/task-manager 8000:8000"
echo ""
echo "  # Terminal 2 - Frontend:"
echo "  kubectl port-forward svc/task-manager-frontend 3000:80"
echo ""
echo "  Puis accède à:"
echo -e "  ${BLUE}• Backend:${NC} http://localhost:8000/docs"
echo -e "  ${BLUE}• Frontend:${NC} http://localhost:3000"
echo ""
echo -e "${GREEN}📝 Note:${NC} Si les LoadBalancers ne sont pas créés, vérifie que le service"
echo "  type soit 'LoadBalancer' dans les Helm values."
echo ""

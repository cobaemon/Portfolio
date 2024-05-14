from django.http import JsonResponse
import json
import logging

logger = logging.getLogger('csp_report')

def csp_report(request):
    if request.method == 'POST':
        report = json.loads(request.body)
        # ログに記録
        logger.info(json.dumps(report))
        return JsonResponse({'status': 'success'})
    return JsonResponse({'status': 'failed'}, status=400)

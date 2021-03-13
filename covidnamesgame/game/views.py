from django.core.exceptions import ObjectDoesNotExist
from django.http import JsonResponse
from django.views.generic.base import TemplateView

from game.models import Player, Session


class LandingView(TemplateView):
    template_name = 'game/game.html'


def find_player(request):
    if request.method == 'GET':
        player_name = request.GET.get('player-name')
        try:
            player = Player.objects.get(name=player_name)
        except ObjectDoesNotExist:
            player = Player(name=player_name, color='R').save()
            print("Player didn't exist, was created")
        return JsonResponse(player)


# based on searchViaInterface()
def find_session(session_code):
    session = Session.objects.get(code=session_code)
    if session is not None:
        return session

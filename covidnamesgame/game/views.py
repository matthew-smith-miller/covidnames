from django.views.generic.base import TemplateView

from game.models import Player, Session


class LandingView(TemplateView):
    template_name = 'game/game.html'


def find_player(player_name):
    player = Player.objects.get(name=player_name)
    if player.session is not None:
        session_code = player.session.code
        find_session(session_code)
    return player


# based on searchViaInterface()
def find_session(session_code):
    session = Session.objects.get(code=session_code)
    if session is not None:
        return session

from django.test import tag, TestCase
from game.models import Player


class CreatePlayerTestCase(TestCase):
    TEST_KWARGS = {
        'name': 'Neil',
        'color': 'R',
        'is_spymaster': False,
    }

    @tag('unit')
    def test_create_player(self):
        p = Player.objects.create(**self.TEST_KWARGS)
        self.assertIsNotNone(p.user)

    @tag('unit')
    def test_model_manager_can_query_by_namne(self):
        Player.objects.create(**self.TEST_KWARGS)

        p = Player.objects.filter(name=self.TEST_KWARGS['name'])
        self.assertEquals(p.count(), 1)

        p = Player.objects.get(name=self.TEST_KWARGS['name'])
        self.assertIsNotNone(p)

        p = Player.objects.exclude(name=self.TEST_KWARGS['name'])
        self.assertEquals(p.count(), 0)

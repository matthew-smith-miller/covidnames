from django.db import models
from django.conf import settings
from django.contrib.auth.models import User


class GameCard(models.Model):
    COLOR_CHOICES = (
        ('R', 'Red'),
        ('B', 'Blue'),
        ('Y', 'Bystander'),
        ('A', 'Assassin'),
    )
    name = models.CharField(max_length=40)
    assigned_color = models.CharField(max_length=1, choices=COLOR_CHOICES)
    image_name = models.CharField(max_length=40)
    is_revealed = models.BooleanField(default=False)
    game = models.ForeignKey(
        'Game', on_delete=models.CASCADE, related_name='game_cards')


class Game(models.Model):
    COLOR_CHOICES = (
        ('R', 'Red'),
        ('B', 'Blue'),
    )
    is_active = models.BooleanField(default=True)
    color = models.CharField(max_length=1, choices=COLOR_CHOICES)
    session = models.ForeignKey(
        'Session', related_name='games', on_delete=models.CASCADE)

    def count_cards_remaining(self):
        blue_cards_remaining = 0
        red_cards_remaining = 0
        for game_card in self.game_cards.all():
            if not game_card.is_revealed:
                if game_card.assigned_color == 'B':
                    blue_cards_remaining += 1
                elif game_card.assigned_color == 'R':
                    red_cards_remaining += 1
        return blue_cards_remaining, red_cards_remaining


class Session(models.Model):
    IMAGE_SET_CHOICES = (
        ('O', 'OG Codenames'),
        ('U', 'Uptown'),
        ('M', 'Miller'),
    )
    code = models.CharField(max_length=9)
    image_set = models.CharField(max_length=1, choices=IMAGE_SET_CHOICES)
    cards_used = models.TextField()


class PlayerQuerySet(models.QuerySet):
    @staticmethod
    def _replace_kwargs(kwargs):
        new_kwargs = {}
        for key, value in kwargs.items():
            if key.find('name') == 0:
                key = key.replace('name', 'user__username')
            new_kwargs.update({key: value})
        return new_kwargs

    def filter(self, *args, **kwargs):
        kwargs = self._replace_kwargs(kwargs)
        return super().filter(*args, **kwargs)

    def exclude(self, *args, **kwargs):
        kwargs = self._replace_kwargs(kwargs)
        return super().exclude(*args, **kwargs)


class Player(models.Model):
    COLOR_CHOICES = (
        ('R', 'Red'),
        ('B', 'Blue'),
    )
    user = models.OneToOneField(
        User, null=True, on_delete=models.CASCADE)
    color = models.CharField(max_length=1, choices=COLOR_CHOICES)
    is_spymaster = models.BooleanField(default=False)
    session = models.ForeignKey(
        'Session', related_name='players',
        null=True, on_delete=models.SET_NULL)

    objects = PlayerQuerySet.as_manager()

    @property
    def name(self):
        return self.user.username

    @name.setter
    def name(self, _name):
        self._name = _name
        if self.user is None:
            self._create_user()

    def _create_user(self):
        self.user = User.objects.create_user(
            username=self._name,
            password=settings.DEFAULT_USER_PASSWORD)

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        name = kwargs.pop('name', None)
        if name is not None:
            self._name = name

    def save(self, *args, **kwargs):
        if self.user is None:
            self._create_user()
        return super().save(*args, **kwargs)


class Configuration(models.Model):
    name = models.CharField(max_length=40)
    content = models.TextField()



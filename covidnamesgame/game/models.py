from django.db import models


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


class Player(models.Model):
    COLOR_CHOICES = (
        ('R', 'Red'),
        ('B', 'Blue'),
    )
    name = models.CharField(max_length=40)
    color = models.CharField(max_length=1, choices=COLOR_CHOICES)
    is_spymaster = models.BooleanField(default=False)
    session = models.ForeignKey('Session', on_delete=models.CASCADE)


class Configuration(models.Model):
    name = models.CharField(max_length=40)
    content = models.TextField()



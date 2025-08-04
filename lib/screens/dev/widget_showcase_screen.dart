
import 'package:flutter/material.dart';
import 'package:skyscraper/widgets/post_card.dart';
import 'package:skyscraper/models/post.dart';
import 'package:faker/faker.dart';

class WidgetShowcaseScreen extends StatelessWidget {
  const WidgetShowcaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final faker = Faker();
    final mockPost = Post(
      author: Actor(
        did: 'did:plc:z72i7hdynmk6r22z27h6tvur',
        handle: 'shinyakato.bsky.social',
        displayName: 'Shinya Kato',
        avatar: 'https://picsum.photos/200',
      ),
      text: faker.lorem.sentences(3).join('\n'),
      createdAt: DateTime.now(),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Widget Showcase'),
      ),
      body: ListView(
        children: [
          PostCard(post: mockPost),
          PostCard(
            post: mockPost.copyWith(
              author: mockPost.author.copyWith(avatar: null),
            ),
          ),
        ],
      ),
    );
  }
}

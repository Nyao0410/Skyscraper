
import 'package:faker/faker.dart';
import 'package:skyscraper/models/post.dart';

final faker = Faker();

final mockPost = Post(
  author: Actor(
    did: 'did:plc:z72i7hdynmk6r22z27h6tvur',
    handle: 'shinyakato.bsky.social',
    displayName: 'Shinya Kato',
    avatar: 'https://cdn.bsky.app/img/avatar/plain/user/bafkreiar2zmyzlh5qixnfe3moqjgzx3s6e4g3v55z4k4f4g5g5d5a5a5a5@jpeg',
  ),
  text: faker.lorem.sentence(),
  createdAt: DateTime.now(),
);

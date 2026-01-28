import 'package:equatable/equatable.dart';

abstract class FeedEvent extends Equatable {
  const FeedEvent();

  @override
  List<Object?> get props => [];
}

class FeedLoadRequested extends FeedEvent {
  const FeedLoadRequested();
}

class FeedRefreshRequested extends FeedEvent {
  const FeedRefreshRequested();
}

class FeedLoadMoreRequested extends FeedEvent {
  const FeedLoadMoreRequested();
}

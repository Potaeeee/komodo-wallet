import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/bloc/auth_bloc/auth_bloc.dart';
import 'package:web_dex/model/authorize_mode.dart';
import 'package:web_dex/shared/widgets/connect_wallet/connect_wallet_button.dart';
import 'package:web_dex/views/wallets_manager/wallets_manager_events_factory.dart';

class ConnectWalletWrapper extends StatelessWidget {
  const ConnectWalletWrapper({
    Key? key,
    required this.child,
    required this.eventType,
    this.withIcon = false,
    this.buttonSize,
  }) : super(key: key);

  final Widget child;
  final Size? buttonSize;
  final bool withIcon;
  final WalletsManagerEventType eventType;

  @override
  Widget build(BuildContext context) {
    final AuthorizeMode mode = context.watch<AuthBloc>().state.mode;

    return mode == AuthorizeMode.logIn
        ? child
        : ConnectWalletButton(
            buttonSize: buttonSize,
            withIcon: withIcon,
            eventType: eventType,
          );
  }
}

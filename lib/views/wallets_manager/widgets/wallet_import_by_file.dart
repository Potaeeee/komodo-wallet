import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:web_dex/blocs/blocs.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/wallet.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/shared/ui/ui_gradient_icon.dart';

import 'package:web_dex/shared/utils/encryption_tool.dart';
import 'package:web_dex/shared/widgets/password_visibility_control.dart';

class WalletFileData {
  const WalletFileData({required this.content, required this.name});
  final String content;
  final String name;
}

class WalletImportByFile extends StatefulWidget {
  const WalletImportByFile({
    Key? key,
    required this.fileData,
    required this.onImport,
    required this.onCancel,
  }) : super(key: key);
  final WalletFileData fileData;

  final void Function({
    required String name,
    required String password,
    required WalletConfig walletConfig,
  }) onImport;
  final void Function() onCancel;

  @override
  State<WalletImportByFile> createState() => _WalletImportByFileState();
}

class _WalletImportByFileState extends State<WalletImportByFile> {
  final TextEditingController _filePasswordController =
      TextEditingController(text: '');
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isObscured = true;

  String? _filePasswordError;
  String? _commonError;

  bool get _isValidData {
    return _filePasswordError == null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          LocaleKeys.walletImportByFileTitle.tr(),
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
                fontSize: 18,
              ),
        ),
        const SizedBox(height: 36),
        Text(LocaleKeys.walletImportByFileDescription.tr(),
            style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 22),
        Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              UiTextFormField(
                key: const Key('file-password-field'),
                controller: _filePasswordController,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                enableInteractiveSelection: true,
                obscureText: _isObscured,
                validator: (_) {
                  return _filePasswordError;
                },
                errorMaxLines: 6,
                hintText: LocaleKeys.walletCreationPasswordHint.tr(),
                suffixIcon: PasswordVisibilityControl(
                  onVisibilityChange: (bool isPasswordObscured) {
                    setState(() {
                      _isObscured = isPasswordObscured;
                    });
                  },
                ),
              ),
              const SizedBox(height: 30),
              Row(children: [
                const UiGradientIcon(
                  icon: Icons.folder,
                ),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(
                  widget.fileData.name,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                )),
              ]),
              if (_commonError != null)
                Align(
                  alignment: const Alignment(-1, 0),
                  child: SelectableText(
                    _commonError ?? '',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge!
                        .copyWith(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              const SizedBox(height: 30),
              const UiDivider(),
              const SizedBox(height: 30),
              UiPrimaryButton(
                key: const Key('confirm-password-button'),
                height: 50,
                text: LocaleKeys.import.tr(),
                onPressed: _onImport,
              ),
              const SizedBox(height: 20),
              UiUnderlineTextButton(
                onPressed: widget.onCancel,
                text: LocaleKeys.back.tr(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _filePasswordController.dispose();

    super.dispose();
  }

  Future<void> _onImport() async {
    final EncryptionTool encryptionTool = EncryptionTool();
    final String? fileData = await encryptionTool.decryptData(
      _filePasswordController.text,
      widget.fileData.content,
    );
    if (fileData == null) {
      setState(() {
        _filePasswordError = LocaleKeys.invalidPasswordError.tr();
      });
      _formKey.currentState?.validate();
      return;
    } else {
      setState(() {
        _filePasswordError = null;
      });
    }
    _formKey.currentState?.validate();
    try {
      final WalletConfig walletConfig =
          WalletConfig.fromJson(json.decode(fileData));
      final String? decryptedSeed = await encryptionTool.decryptData(
          _filePasswordController.text, walletConfig.seedPhrase);
      if (decryptedSeed == null) return;
      if (!_isValidData) return;

      walletConfig.seedPhrase = decryptedSeed;

      final String name = widget.fileData.name.split('.').first;
      final bool isNameExisted =
          walletsBloc.wallets.firstWhereOrNull((w) => w.name == name) != null;
      if (isNameExisted) {
        setState(() {
          _commonError = LocaleKeys.walletCreationExistNameError.tr();
        });
        return;
      }
      widget.onImport(
        name: name,
        password: _filePasswordController.text,
        walletConfig: walletConfig,
      );
    } catch (_) {
      setState(() {
        _commonError = LocaleKeys.somethingWrong.tr();
      });
    }
  }
}

// 🔵 FACEBOOK SIGN IN FUNCTION (Bypasses PigeonUserDetails TypeCast Bug)
  Future<void> _signInWithFacebook() async {
    try {
      // 1. Log out existing local session first to prevent stale token issues
      await FacebookAuth.instance.logOut();

      // 2. Request Express Login with standard permissions
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
        loginBehavior: LoginBehavior.nativeWithFallback,
      );

      if (result.status == LoginStatus.success) {
        final AccessToken accessToken = result.accessToken!;
        final OAuthCredential credential = FacebookAuthProvider.credential(accessToken.tokenString);

        UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

        setState(() {
          _currentUser = userCredential.user;
          userProfile.name = _currentUser?.displayName ?? "Player 1";
          _nameController.text = userProfile.name;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Logged in as ${userProfile.name}"), backgroundColor: Colors.green),
        );
      } else if (result.status == LoginStatus.cancelled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Facebook Login Cancelled"), backgroundColor: Colors.orange),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Facebook Login Failed: ${result.message}"), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      // 3. Fallback catch block for Pigeon TypeCast Exception in v7.x
      try {
        final AccessToken? accessToken = await FacebookAuth.instance.accessToken;
        if (accessToken != null && !accessToken.isExpired) {
          final OAuthCredential credential = FacebookAuthProvider.credential(accessToken.tokenString);
          UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

          setState(() {
            _currentUser = userCredential.user;
            userProfile.name = _currentUser?.displayName ?? "Player 1";
            _nameController.text = userProfile.name;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Logged in as ${userProfile.name}"), backgroundColor: Colors.green),
          );
          return;
        }
      } catch (_) {}

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Facebook Sign In Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

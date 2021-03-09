export default {
  copy: {
    success: 'Text Copied!',
    failure: 'Could not copy Text',
  },
  copyGitRevision: {
    success: 'Git Revision Copied!',
    failure: 'Could not copy Git Revision',
  },
  copyImageUrl: {
    success: 'Image URL Copied!',
    failure: 'Could not copy Image URL',
  },
  copyVideoUrl: {
    success: 'Video URL Copied!',
    failure: 'Could not copy Video URL',
  },
  signup: {
    success:
      '<b>Welcome to FleetYards.net!</b> Your account has been created. <br>You will receive a confirmation email to activate your account.',
    invalid: 'Please resolve the errors before your account can be created.',
    failure: 'We could not create your account. Please try again later.',
  },
  accountConfirm: {
    success: 'Your account was successfully confirmed.<br>You can now login.',
    failure: 'Your account could not be confirmed.',
  },
  requestPasswordChange: {
    success:
      'If your email address exists in our database, you will receive a password recovery link at your email address in a few minutes.',
  },
  changePassword: {
    success: 'Your password was changed successfully.',
    failure: 'Your password could not be updated.',
  },
  updateProfile: {
    success: 'Profile updated.',
  },
  avatarUpload: {
    success: 'Avatar uploaded',
    invalidExtension:
      'The Picture you provided has an invalid Format. Supported Formats are: %{extensions}.',
  },
  hangarImport: {
    success: 'Import completed',
    partialSuccess:
      'Import partially completed.<br><br>Not found Ships: <br>%{missing}',
    failure: 'Import failed',
    invalidExtension:
      'The Import you provided has an invalid Format. Supported Formats are: %{extensions}.',
  },
  hangarExport: {
    failure: 'Export failed, Please try again later.',
  },
  vehicle: {
    add: {
      success:
        'Your new <b>%{model}</b> will be delivered to your <a href="/hangar">Hangar</a>',
    },
  },
  model: {
    onSale: '%{model} now on Sale!',
  },
  notification: {
    granted: 'Welcome to FleetYards.net Notifications!',
  },
  error: {
    usernameTaken: 'Username is already taken.',
    userNotFound: 'User not found',
    urlInvalid: 'URL is invalid',
    emailTaken: 'E-Mail is already taken.',
    fleetTaken: 'Fleet is already taken.',
    serialTaken: 'Serial is already taken.',
    hangar: {
      accountRequired:
        'You need to <a href="/sign-up/">Sign up</a> or <a href="/login/">Login</a> to add Ships to your Hangar.<br>Get more Information <a href="/hangar/preview/">here</a>',
    },
    commodityPrice: {
      accountRequired:
        'You need to <a href="/sign-up/">Sign up</a> or <a href="/login/">Login</a> to submit Prices.',
    },
    default:
      '<b>Something wrong happened.</b> <br>Have you tried turning it off and on again?',
  },
  account: {
    destroy: {
      success:
        "<b>Your Account has been destroyed.</b> <br>Sad to see you go :'(",
      failure: 'We could not destroy your Account! Please try again later.',
    },
  },
  commodityPrice: {
    create: {
      success: 'Thank you for your price submission.',
    },
  },
  fleet: {
    create: {
      success: 'Your Fleet has been created.',
      failure: 'Fleet could not be saved.',
    },
    update: {
      success: 'Settings saved.',
      failure: 'Settings could not be saved.',
    },
    destroy: {
      success: 'Your Fleet has been destroyed.',
      failure: 'We could not destroy your Fleet.',
    },
    leave: {
      success: 'You have left the Fleet.',
      failure: 'Could not leave the Fleet.',
    },
    invites: {
      accept: {
        success: 'Invite accepted.',
        failure: 'Could not accept Invite.',
      },
      decline: {
        success: 'Invite declined.',
        failure: 'Could not decline Invite.',
      },
      create: {
        failure: 'Could not invite User.',
      },
    },
    members: {
      update: {
        success: 'Settings saved.',
        failure: 'Settings could not be saved.',
      },
      destroy: {
        success: 'Member removed.',
        failure: 'Member could not be removed.',
      },
      demote: {
        success: 'Member demoted.',
        failure: 'Member could not be demoted.',
      },
      promote: {
        success: 'Member promoted.',
        failure: 'Member could not be promoted.',
      },
    },
  },
  confirm: {
    vehicle: {
      destroy: 'Are you sure you want to remove this Ship from you Hangar?',
    },
    hangarGroup: {
      destroy: 'Are you sure you want to remove this Group from you Hangar?',
    },
    hangar: {
      import:
        'Imported ships will be added to your Hangar without matching to exisiting Ships.<br><br>Supported Formats are: Fleetyards Export, Starship42 or HangarXplor.<br><br>Do you want to continue?',
      destroySelected:
        "Are you sure you want to remove all Selected Ships from you Hangar? This Action can't be reverted.",
      destroyAll:
        "Are you sure you want to remove all Ships from you Hangar? This Action can't be reverted.",
    },
    tradeRoutes: {
      reset: 'Are you sure you want to reset all commodity prices?',
    },
    account: {
      destroy:
        "Are you sure you want to destroy your Account? This Action can't be reverted.",
    },
    commodityPrice: {
      destroy:
        "Are you sure you want to destroy this Price? This Action can't be reverted.",
    },
    shopCommodity: {
      destroy:
        "Are you sure you want to destroy this Commodity? This Action can't be reverted.",
    },
    fleet: {
      leave:
        "Are you sure you want to leave the Fleet? This Action can't be reverted.",
      destroy:
        "Are you sure you want to destroy your Fleet? This Action can't be reverted.",
      members: {
        destroy: 'Are you sure you want to remove this Member?',
      },
      invites: {
        decline:
          "Are you sure you want to decline this Invite? This Action can't be reverted.",
      },
    },
  },
}

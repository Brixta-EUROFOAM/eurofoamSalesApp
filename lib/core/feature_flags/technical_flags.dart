class TechnicalFlags {
  final bool attendance;
  final bool masonManagement;
  //mason management stuff
  final bool approveBagLift;
  final bool approveKyc;
  final bool approveRewards;
  final bool myMasons;
  final bool technicalOps;
  final bool createTvr;
  final bool registerSite;
  final bool addDealerSubDealer;

  const TechnicalFlags({
    required this.attendance,
    required this.masonManagement,
    required this.approveBagLift,
    required this.approveKyc,
    required this.approveRewards,
    required this.myMasons,
    required this.technicalOps,
    required this.createTvr,
    required this.registerSite,
    required this.addDealerSubDealer,
  });

  // 👇 THIS IS THE SWITCH (FOR NOW)
  static const TechnicalFlags dev = TechnicalFlags(
    attendance: true,
    masonManagement: true,
    technicalOps: true,
    approveBagLift: true,
    approveKyc: true,
    approveRewards: true,
    myMasons: true,
    createTvr: true,
    registerSite: true,
    addDealerSubDealer: true,
  );
}

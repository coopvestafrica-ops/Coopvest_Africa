enum InvestmentType {
  fixedIncome,
  equity,
  mutualFund,
  realEstate,
  agriculture,
  microfinance,
  other;

  String get displayName {
    switch (this) {
      case InvestmentType.fixedIncome:
        return 'Fixed Income';
      case InvestmentType.equity:
        return 'Equity';
      case InvestmentType.mutualFund:
        return 'Mutual Fund';
      case InvestmentType.realEstate:
        return 'Real Estate';
      case InvestmentType.agriculture:
        return 'Agriculture';
      case InvestmentType.microfinance:
        return 'Microfinance';
      case InvestmentType.other:
        return 'Other';
    }
  }

  bool get isHighRisk {
    return this == InvestmentType.equity || 
           this == InvestmentType.agriculture;
  }

  bool get isLowRisk {
    return this == InvestmentType.fixedIncome || 
           this == InvestmentType.microfinance;
  }

  bool get isMediumRisk {
    return this == InvestmentType.mutualFund || 
           this == InvestmentType.realEstate;
  }

  double get recommendedAllocation {
    switch (this) {
      case InvestmentType.fixedIncome:
        return 40.0;
      case InvestmentType.equity:
        return 20.0;
      case InvestmentType.mutualFund:
        return 15.0;
      case InvestmentType.realEstate:
        return 10.0;
      case InvestmentType.agriculture:
        return 10.0;
      case InvestmentType.microfinance:
        return 5.0;
      case InvestmentType.other:
        return 0.0;
    }
  }
}

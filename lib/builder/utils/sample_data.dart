class SampleData {
  static const String sampleXml = '''
<?xml version="1.0" encoding="UTF-8"?>
<RailwayData>
  <Blocks>
    <Block id="100" startX="0.0" endX="200.0" y="100.0" occupied="false" occupyingTrain="none" />
    <Block id="102" startX="200.0" endX="400.0" y="100.0" occupied="false" occupyingTrain="none" />
    <Block id="104" startX="400.0" endX="600.0" y="100.0" occupied="false" occupyingTrain="none" />
    <Block id="106" startX="600.0" endX="800.0" y="100.0" occupied="false" occupyingTrain="none" />
    <Block id="108" startX="800.0" endX="1000.0" y="100.0" occupied="false" occupyingTrain="none" />
    <Block id="110" startX="1000.0" endX="1200.0" y="100.0" occupied="false" occupyingTrain="none" />
    <Block id="112" startX="1200.0" endX="1400.0" y="100.0" occupied="false" occupyingTrain="none" />
    <Block id="114" startX="1400.0" endX="1600.0" y="100.0" occupied="false" occupyingTrain="none" />
    <Block id="101" startX="0.0" endX="200.0" y="300.0" occupied="false" occupyingTrain="none" />
    <Block id="103" startX="200.0" endX="400.0" y="300.0" occupied="false" occupyingTrain="none" />
    <Block id="105" startX="400.0" endX="600.0" y="300.0" occupied="false" occupyingTrain="none" />
    <Block id="107" startX="600.0" endX="800.0" y="300.0" occupied="false" occupyingTrain="none" />
    <Block id="109" startX="800.0" endX="1000.0" y="300.0" occupied="false" occupyingTrain="none" />
    <Block id="111" startX="1000.0" endX="1200.0" y="300.0" occupied="false" occupyingTrain="none" />
    <Block id="crossover106" startX="600.0" endX="700.0" y="150.0" occupied="false" occupyingTrain="none" />
    <Block id="crossover109" startX="700.0" endX="800.0" y="250.0" occupied="false" occupyingTrain="none" />
  </Blocks>
  <Points>
    <Point id="78A" x="600.0" y="100.0" position="normal" locked="false" />
    <Point id="78B" x="800.0" y="300.0" position="normal" locked="false" />
  </Points>
  <Signals>
    <Signal id="C31" x="390.0" y="80.0" aspect="red" state="unset">
      <Route id="C31_R1" name="Route 1 (Main → Platform 1)">
        <RequiredBlocks>106, 108, 110, 112</RequiredBlocks>
        <PathBlocks>104, 106, 108, 110, 112</PathBlocks>
        <ConflictingRoutes></ConflictingRoutes>
      </Route>
      <Route id="C31_R2" name="Route 2 (Main → Bay Platform 2)">
        <RequiredBlocks>106, crossover106, crossover109, 109, 111</RequiredBlocks>
        <PathBlocks>104, 106, crossover106, crossover109, 109, 111</PathBlocks>
        <ConflictingRoutes>C30_R1, C30_R2</ConflictingRoutes>
      </Route>
    </Signal>
    <Signal id="C33" x="1210.0" y="80.0" aspect="red" state="unset">
      <Route id="C33_R1" name="Platform 1 Departure">
        <RequiredBlocks>112, 114</RequiredBlocks>
        <PathBlocks>112, 114</PathBlocks>
        <ConflictingRoutes></ConflictingRoutes>
      </Route>
    </Signal>
    <Signal id="C30" x="980.0" y="320.0" aspect="red" state="unset">
      <Route id="C30_R1" name="Bay → Westbound (via C28)">
        <RequiredBlocks>107, 105, 103</RequiredBlocks>
        <PathBlocks>109, 107, 105, 103, 101</PathBlocks>
        <ConflictingRoutes></ConflictingRoutes>
      </Route>
      <Route id="C30_R2" name="Bay → Eastbound (via Crossover)">
        <RequiredBlocks>104, 102, crossover109, crossover106, 106, 108</RequiredBlocks>
        <PathBlocks>109, crossover109, crossover106, 106, 108, 110</PathBlocks>
        <ConflictingRoutes>C31_R1, C31_R2</ConflictingRoutes>
      </Route>
    </Signal>
    <Signal id="C28" x="380.0" y="320.0" aspect="red" state="unset">
      <Route id="C28_R1" name="Bay Exit (Westbound)">
        <RequiredBlocks>103, 101</RequiredBlocks>
        <PathBlocks>105, 103, 101</PathBlocks>
        <ConflictingRoutes></ConflictingRoutes>
      </Route>
    </Signal>
  </Signals>
  <Platforms>
    <Platform id="P1" name="Platform 1" startX="980.0" endX="1240.0" y="100.0" occupied="false" />
    <Platform id="P2" name="Platform 2 (Bay)" startX="980.0" endX="1240.0" y="300.0" occupied="false" />
  </Platforms>
</RailwayData>
''';
}

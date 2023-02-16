import * as React from 'react';

import { StyleSheet, View, Text } from 'react-native';
import { exportPhotoAssets } from 'react-native-ios-assset-exporter';

export default function App() {
  const [result, setResult] = React.useState<number | undefined>();

  React.useEffect(() => {
    exportPhotoAssets(['1', '2'], '/tmp', 'test', true, true).then((results) => {
      setResult(results.exportResults?.length);
    })
  }, []);

  return (
    <View style={styles.container}>
      <Text>Result: {result}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  box: {
    width: 60,
    height: 60,
    marginVertical: 20,
  },
});

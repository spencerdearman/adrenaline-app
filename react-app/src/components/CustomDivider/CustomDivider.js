import React from 'react';

import { Divider } from '@aws-amplify/ui-react';

export const CustomDivider = ({ marginTop = 20, marginBottom = 20, borderWidth = 0.5 }) => {
  return <Divider style={{ marginTop, marginBottom, borderWidth }} />;
};

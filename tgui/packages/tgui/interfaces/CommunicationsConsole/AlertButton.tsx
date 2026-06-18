import { Button } from 'tgui-core/components';
import { capitalize } from 'tgui-core/string';

import { useBackend } from '../../backend';
import {
  type AlertLevel,
  CanSetAlertLevel,
  type CommsConsoleData,
} from './types';

type Props = {
  newAlertLevel: AlertLevel;
  onClick: () => void;
};

export function AlertButton(props: Props) {
  const { newAlertLevel, onClick } = props;

  const { act, data } = useBackend<CommsConsoleData>();
  const { canSetAlertLevel } = data;

  const thisIsCurrent = data.alertLevel.name === newAlertLevel.name;

  return (
    <Button
      icon="exclamation-triangle"
      color={thisIsCurrent && 'good'}
      onClick={() => {
        if (thisIsCurrent) {
          return;
        }

        if (canSetAlertLevel === CanSetAlertLevel.SWIPE_NEEDED) {
          onClick();
        } else {
          act('changeSecurityLevel', {
            newSecurityLevel: newAlertLevel.name,
          });
        }
      }}
    >
      {capitalize(newAlertLevel.name)}
    </Button>
  );
}
